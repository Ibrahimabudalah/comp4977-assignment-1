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

            VotingGuideView()
                .tabItem {
                    Label("Voting Guide", systemImage: "bookmark")
                }

            ProfileView(viewModel: authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .environmentObject(votingGuide)
        .sheet(isPresented: $showingFirstTimeMunicipalitySheet) {
            MunicipalitySelectionView(isMandatory: true)
        }
        .task {
            // Load available municipalities and check if user needs first-time setup
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
}
