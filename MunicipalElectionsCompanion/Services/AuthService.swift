
import Foundation

final class AuthService {
    static let shared = AuthService()

    private init() {}

    func login(
        email: String,
        password: String
    ) async throws -> TokenResponse {
        let request = LoginRequest(
            email: email,
            password: password
        )

        return try await APIService.shared.post(
            "/api/auth/login",
            body: request
        )
    }
}
