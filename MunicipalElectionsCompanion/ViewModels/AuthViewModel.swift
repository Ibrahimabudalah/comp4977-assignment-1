
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoggedIn = false
    @Published var loggedInName = ""
    @Published var loggedInEmail = ""
    @Published var errorMessage = ""
    @Published var isLoading = false

    @Published var name = ""
    @Published var confirmPassword = ""
    @Published var registrationSuccessful = false

    func login() async {
        errorMessage = ""

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let request = LoginRequest(
                email: email,
                password: password
            )

            print(" Sending login request")

            let response: TokenResponse = try await APIService.shared.post(
                "/api/auth/login",
                body: request
            )

            print("Login succeeded, JWT received")

            _ = TokenManager.shared.saveToken(response.token)

            print("Fetching user profile")

            let user: UserResponse = try await APIService.shared.get(
                "/api/auth/me",
                token: response.token
            )

            print("Profile loaded successfully")
            
            print("User profile loaded successfully")

            loggedInName = user.name
            loggedInEmail = user.email
            password = ""
            isLoggedIn = true

            print("Login successful")
        } catch {
            TokenManager.shared.deleteToken()
            errorMessage = "Login failed. Please check your email and password."
            print("Login error: \(error.localizedDescription)")
        }
    }

    func register() async {
        errorMessage = ""
        registrationSuccessful = false

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let request = RegisterRequest(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email,
                password: password
            )

            let _: UserResponse = try await APIService.shared.post(
                "/api/auth/register",
                body: request
            )

            registrationSuccessful = true
            password = ""
            confirmPassword = ""

            print("Registration successful")
        } catch {
            errorMessage = "Registration failed. Check your information and try again."
            print("Registration error: \(error.localizedDescription)")
        }
    }

    func logout() {
        TokenManager.shared.deleteToken()

        isLoggedIn = false
        email = ""
        password = ""
        name = ""
        confirmPassword = ""
        errorMessage = ""
        registrationSuccessful = false
        loggedInName = ""
        loggedInEmail = ""
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return email.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}
