//
//  ContentView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-19.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var votingGuide = VotingGuideViewModel()

    var body: some View {
        TabView {
            MunicipalitiesView()
                .tabItem {
                    Label("Municipalities", systemImage: "building.2")
                }

            NavigationStack {
                CandidateListView()
            }
            .tabItem {
                Label("Candidates", systemImage: "person.3")
            }

            VotingGuideView()
                .tabItem {
                    Label("Voting Guide", systemImage: "bookmark")
                }
        }
        .environmentObject(votingGuide)
    }
}

#Preview {
    ContentView()
}
