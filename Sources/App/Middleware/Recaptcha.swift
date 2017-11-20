import Vapor
import HTTP

final class Recaptcha: Middleware {

    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard
            let config = try? Config(),
            let formData = request.formURLEncoded,
            let recaptchaResponse = formData["g-recaptcha-response"]?.string,
            let recaptchaSecret = config["app", "recaptcha", "secret"]?.string
        else {
            throw Abort(.internalServerError, reason: "Unable to parse recaptcha")
        }

        let url = "https://www.google.com/recaptcha/api/siteverify"
        let query = [
            "secret": recaptchaSecret,
            "response": recaptchaResponse
        ]
        let recaptcha = try EngineClient.factory.post(url, query: query, [:], nil, through: [])

        guard
            let recaptchaJson = recaptcha.json,
            let success = recaptchaJson["success"]?.bool,
            success == true
        else {
            throw Abort(.unauthorized, reason: "Invalid reCAPTCHA response")
        }

        return try next.respond(to: request)
    }
}
