import SwiftUI

@main
struct MunicipalElectionsCompanionApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var selectionsViewModel = CandidateSelectionsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    ContentView(authViewModel: authViewModel)
                        .environmentObject(selectionsViewModel)
                } else {
                    LoginView(viewModel: authViewModel)
                }
            }
            // The login lasts 60 minutes; if it ran out while the app was in the background, sign out.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, authViewModel.isLoggedIn, TokenManager.shared.isTokenExpired() {
                    authViewModel.logout(reason: "Your session has expired. Please log in again.")
                }
            }
        }
    }
}
