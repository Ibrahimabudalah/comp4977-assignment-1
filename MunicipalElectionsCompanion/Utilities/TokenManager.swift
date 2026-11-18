
import Foundation
import Security

final class TokenManager {
    static let shared = TokenManager()

    private let service = "MunicipalElectionsCompanion"
    private let account = "authToken"

    private init() {}

    func saveToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else {
            return false
        }

        deleteToken()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// True when there is no stored token, it can't be read, or its `exp` claim has passed.
    func isTokenExpired() -> Bool {
        guard let token = getToken() else { return true }
        return Self.isExpired(token: token)
    }

    /// Reads the `exp` claim straight from the JWT payload (no signature check: the server
    /// validates that; this only decides whether the app should still treat the session as live).
    static func isExpired(token: String, now: Date = Date()) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return true }

        // JWT payloads are base64url without padding; Data(base64Encoded:) wants standard base64
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)

        guard let data = Data(base64Encoded: base64),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = claims["exp"] as? TimeInterval else {
            return true
        }

        return Date(timeIntervalSince1970: exp) <= now
    }

    @discardableResult
    func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        return status == errSecSuccess ||
               status == errSecItemNotFound
    }
}
