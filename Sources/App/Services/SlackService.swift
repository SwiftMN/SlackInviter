import Foundation
import Vapor
import HTTP
import Cache

enum CacheKey: String {
    case team
    case totalUsers
    case activeUsers
    
    func value(for workspace: String) -> String {
        return "\(workspace).\(rawValue)"
    }
}

final class SlackService {
    
    let cache: CacheProtocol
    
    init(_ drop: Droplet) {
        cache = drop.cache
    }

    private var client: EngineClientFactory {
        return EngineClient.factory
    }
    
    private func slackToken() throws -> String {
        guard
            let config = try? Config(),
            let slackToken = config["app", "slack", "token"]?.string
        else {
            throw Abort(.internalServerError, reason: "Unable to parse token from config")
        }
        return slackToken
    }

    func sendInvite(to email: String) throws {
        let token = try slackToken()
        let url = "https://slack.com/api/users.admin.invite"
        let body = try Node(node: [
            "email": email,
            "token": token
        ]).formURLEncoded()
        let slackResponse = try client.post(
            url,
            query: [:],
            [HeaderKey.contentType: "application/x-www-form-urlencoded"],
            Body.data(body)
        )
        guard
            let slackJson = slackResponse.json,
            let status = slackJson["ok"]?.bool,
            status == true
        else {
            throw Abort(.badRequest, reason: "Request failed")
        }
        print("Successfully sent invite to \(email)")
    }

    func fetchTeam(workspace: String) throws -> Team {
        let cacheKey = CacheKey.team.value(for: workspace)
        if let teamNode = try? cache.get(cacheKey), let team = try? teamNode.converted(to: Team.self, in: nil) {
            print("found team in cache")
            return team
        }
        print("no team in cache; fetching from slack api")
        
        let token = try slackToken()
        let slackUrl = "https://\(workspace).slack.com/api/team.info"
        let teamInfoResponse = try client.get(slackUrl, query: ["token": token], [:], nil, through: [])
        
        let teamInfo = try teamInfoResponse.decode(TeamInfo.self)
        
        let expire = Date(timeIntervalSinceNow: 86400) // expire in 1 day // 1 day * 24 hours * 60 minutes * 60 seconds
        try? cache.set(cacheKey, teamInfo.team.makeNode(in: nil), expiration: expire)
        
        return teamInfo.team
    }

    func fetchUserCounts(workspace: String) throws -> (active: Int, total: Int) {
        let totalUsersKey = CacheKey.totalUsers.value(for: workspace)
        let activeUsersKey = CacheKey.activeUsers.value(for: workspace)
        if
            let totalUsersNode = try? cache.get(totalUsersKey),
            let activeUsersNode = try? cache.get(activeUsersKey),
            let totalUsers = totalUsersNode?.int,
            let activeUsers = activeUsersNode?.int
        {
            print("found user counts in cache")
            return (activeUsers, totalUsers)
        }
        print("no user counts in cache; fetching from slack api")

        let token = try slackToken()
        let slackUrl = "https://swiftmn.slack.com/api/users.list"
        let usersListResponse = try client.get(slackUrl, query: ["token": token, "presence": true], [:], nil, through: [])
        guard
            let json = usersListResponse.json,
            let members = json["members"]?.array
        else {
            throw Abort(.internalServerError, reason: "Failed to parse members list from slack response")
        }

        let total = members.count
        let active = members.reduce(0) { activeCount, member in
            if let presence = member["presence"]?.string, presence == "active" {
                return activeCount + 1
            }
            return activeCount
        }
        
        let expire = Date(timeIntervalSinceNow: 900) // expire in 15 minutes // 15 minutes * 60 seconds
        try? cache.set(totalUsersKey, total.makeNode(in: nil), expiration: expire)
        try? cache.set(activeUsersKey, active.makeNode(in: nil), expiration: expire)

        return (active, total)
    }
}
