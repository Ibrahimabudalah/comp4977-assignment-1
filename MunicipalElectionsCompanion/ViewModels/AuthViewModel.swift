
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

    @Published var name = ""
    @Published var confirmPassword = ""
    @Published var registrationSuccessful = false

    func login() {
        errorMessage = ""

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        //temp mock login
        loggedInEmail = email
        loggedInName = name.isEmpty ? "User" : name
        isLoggedIn = true
    }

    func register() {
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

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        //temp mock regi
        registrationSuccessful = true
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
