import Foundation
import Vapor

struct Team: Codable {
    let id: String
    let name: String
    let domain: String
    let email_domain: String
    let icon: TeamIcon
}

extension Team: NodeRepresentable {
    func makeNode(in context: Context?) throws -> Node {
        var node = Node(nil)
        try node.set("id", id)
        try node.set("name", name)
        try node.set("domain", domain)
        try node.set("email_domain", email_domain)
        try node.set("icon", icon)
        return node
    }
}

extension Team: NodeInitializable {
    init(node: Node) throws {
        try id = node.get("id")
        try name = node.get("name")
        try domain = node.get("domain")
        try email_domain = node.get("email_domain")
        try icon = node.get("icon")
    }
}
