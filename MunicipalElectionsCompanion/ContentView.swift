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

    var body: some View {
        TabView {
            MunicipalitiesView()
                .tabItem {
                    Label(
                        "Municipalities",
                        systemImage: "building.2"
                    )
                }

            NavigationStack {
                CandidateListView()
            }
            .tabItem {
                Label(
                    "Candidates",
                    systemImage: "person.3"
                )
            }

            VotingGuideView()
                .tabItem {
                    Label(
                        "Voting Guide",
                        systemImage: "bookmark"
                    )
                }

            ProfileView(viewModel: authViewModel)
                .tabItem {
                    Label(
                        "Profile",
                        systemImage: "person.crop.circle"
                    )
                }
        }
        .environmentObject(votingGuide)
    }
}

#Preview {
    ContentView(authViewModel: AuthViewModel())
        .environmentObject(VotingGuideViewModel())
}
