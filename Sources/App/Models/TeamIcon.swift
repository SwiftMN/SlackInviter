import Foundation
import Vapor

struct TeamIcon: Codable {
    let image_34: String
    let image_44: String
    let image_68: String
    let image_88: String
    let image_102: String
    let image_132: String
    let image_230: String
    let image_original: String
}

extension TeamIcon: NodeRepresentable {
    func makeNode(in context: Context?) throws -> Node {
        var node = Node(nil)
        try node.set("image_34", image_34)
        try node.set("image_44", image_44)
        try node.set("image_68", image_68)
        try node.set("image_88", image_88)
        try node.set("image_102", image_102)
        try node.set("image_132", image_132)
        try node.set("image_230", image_230)
        try node.set("image_original", image_original)
        return node
    }
}
extension TeamIcon: NodeInitializable {
    init(node: Node) throws {
        image_34 = try node.get("image_34")
        image_44 = try node.get("image_44")
        image_68 = try node.get("image_68")
        image_88 = try node.get("image_88")
        image_102 = try node.get("image_102")
        image_132 = try node.get("image_132")
        image_230 = try node.get("image_230")
        image_original = try node.get("image_original")
    }
}
