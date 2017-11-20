import Foundation
import Vapor

struct TeamInfo: Codable {
    let ok: Bool
    let team: Team
}
