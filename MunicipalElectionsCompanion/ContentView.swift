//
//  ContentView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-19.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var votingGuide: VotingGuideViewModel
    @EnvironmentObject var selectionsViewModel: CandidateSelectionsViewModel
    @ObservedObject var municipalityManager = MunicipalityManager.shared

    @State private var showingFirstTimeMunicipalitySheet = false

    var body: some View {
        TabView {
            NavigationStack {
                CandidateListView()
            }
            .tabItem {
                Label("Candidates", systemImage: "person.3")
            }

            MunicipalitiesView()
                .tabItem {
                    Label("Municipalities", systemImage: "building.2")
                }

            CandidateSelectionsView()
                .tabItem {
                    Label("My Selections", systemImage: "checkmark.seal")
                }

            ProfileView(viewModel: authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .environmentObject(votingGuide)
        .environmentObject(selectionsViewModel)
        .sheet(isPresented: $showingFirstTimeMunicipalitySheet) {
            MunicipalitySelectionView(isMandatory: true)
        }
        .task {
            // Restore user's municipality preference and selections
            municipalityManager.setUserEmail(authViewModel.loggedInEmail)
            selectionsViewModel.setUserEmail(authViewModel.loggedInEmail)
            await municipalityManager.loadAvailableMunicipalities()
            if !municipalityManager.hasSelectedMunicipality {
                showingFirstTimeMunicipalitySheet = true
            }
        }
    }
}

#Preview {
    ContentView(authViewModel: AuthViewModel())
        .environmentObject(VotingGuideViewModel())
        .environmentObject(CandidateSelectionsViewModel())
}
