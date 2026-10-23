
import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}

struct TokenResponse: Decodable {
    let token: String
}

struct UserResponse: Decodable {
    let name: String
    let email: String
}
