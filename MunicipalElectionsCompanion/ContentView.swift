//
//  ContentView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-19.
//

import SwiftUI

enum NavigationTab: String, Hashable, CaseIterable, Identifiable {
    case candidates = "Candidates"
    case municipalities = "Municipalities"
    case selections = "My Selections"
    case profile = "Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .candidates: return "person.3"
        case .municipalities: return "building.2"
        case .selections: return "checkmark.seal"
        case .profile: return "person.crop.circle"
        }
    }
}

struct ContentView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var votingGuide: VotingGuideViewModel
    @EnvironmentObject var selectionsViewModel: CandidateSelectionsViewModel
    @ObservedObject var municipalityManager = MunicipalityManager.shared

    @State private var showingFirstTimeMunicipalitySheet = false
    @State private var selectedTab: NavigationTab? = .candidates
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Group {
            if isIPad {
                // iPad Adaptive Sidebar with NavigationSplitView
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    List(NavigationTab.allCases, selection: $selectedTab) { tab in
                        NavigationLink(value: tab) {
                            Label(tab.rawValue, systemImage: tab.icon)
                        }
                    }
                    .navigationTitle("Elections")
                    .safeAreaInset(edge: .bottom) {
                        if let municipality = municipalityManager.selectedMunicipality {
                            HStack(spacing: 10) {
                                RemoteImageView(
                                    urlString: municipality.displayLogoUrl,
                                    fallbackSystemName: "building.2.crop.circle",
                                    size: 36,
                                    shape: .roundedRectangle(cornerRadius: 8),
                                    fallbackColor: .blue
                                )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(municipality.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text("Active City")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(12)
                        }
                    }
                } detail: {
                    detailView(for: selectedTab ?? .candidates)
                }
            } else {
                // iPhone Native TabBar
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

    @ViewBuilder
    private func detailView(for tab: NavigationTab) -> some View {
        switch tab {
        case .candidates:
            NavigationStack {
                CandidateListView()
            }
        case .municipalities:
            MunicipalitiesView()
        case .selections:
            CandidateSelectionsView()
        case .profile:
            ProfileView(viewModel: authViewModel)
        }
    }
}

#Preview {
    ContentView(authViewModel: AuthViewModel())
        .environmentObject(VotingGuideViewModel())
        .environmentObject(CandidateSelectionsViewModel())
}
