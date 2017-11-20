import Vapor
import HTTP
import LeafProvider

extension Droplet {
    func setupRoutes() throws {
        
        get { _ in
            return try self.buildView(view: "invite")
        }
        get("thanks") { _ in
            return try self.buildView(view: "thanks")
        }

        grouped(Recaptcha()).post("invite") { request in
            guard
                let formData = request.formURLEncoded,
                let email = formData["email"]?.string
            else {
                throw Abort(.badRequest, reason: "Missing email")
            }

            let slack = SlackService(self)
            try slack.sendInvite(to: email)

            return Response(redirect: "thanks")
        }
    }

    private func buildView(view: String) throws -> View {
        guard
            let workspace = self.config["app", "slack", "workspace"]?.string,
            let sitekey = self.config["app", "recaptcha", "sitekey"]?.string
        else {
            throw Abort(.internalServerError, reason: "Unable to parse token from config")
        }
        let slack = SlackService(self)
        let team = try slack.fetchTeam(workspace: workspace)
        let userCounts = try slack.fetchUserCounts(workspace: workspace)
        return try self.view.make(view, [
            "name": team.name,
            "activeUsers": userCounts.0,
            "totalUsers": userCounts.1,
            "orgUrl": team.icon.image_132,
            "workspace": workspace,
            "sitekey": sitekey
        ])
    }
}
