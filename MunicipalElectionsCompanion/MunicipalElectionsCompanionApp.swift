import SwiftUI

@main
struct MunicipalElectionsCompanionApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var votingGuide = VotingGuideViewModel()
    @StateObject private var selectionsViewModel = CandidateSelectionsViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    ContentView(authViewModel: authViewModel)
                        .environmentObject(votingGuide)
                        .environmentObject(selectionsViewModel)
                } else {
                    LoginView(viewModel: authViewModel)
                }
            }
        }
    }
}
