import SwiftUI

@main
struct MunicipalElectionsCompanionApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var votingGuide = VotingGuideViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    ContentView(authViewModel: authViewModel)
                        .environmentObject(votingGuide)
                } else {
                    LoginView(viewModel: authViewModel)
                }
            }
        }
    }
}
