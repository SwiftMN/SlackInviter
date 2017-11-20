import Foundation
import HTTP

extension Response {
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard let bytes = body.bytes else {
            throw Abort.badRequest
        }
        let data = Data(bytes: bytes)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}
