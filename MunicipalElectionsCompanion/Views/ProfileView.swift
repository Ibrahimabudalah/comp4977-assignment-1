//
//  ProfileView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var selectionsViewModel: CandidateSelectionsViewModel
    @ObservedObject var municipalityManager = MunicipalityManager.shared

    @State private var showingMunicipalitySheet = false

    var body: some View {
        NavigationStack {
            Form {
                // User Avatar Section
                Section {
                    HStack {
                        Spacer()

                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue)

                            Text(viewModel.loggedInName.isEmpty ? "Voter" : viewModel.loggedInName)
                                .font(.title2)
                                .bold()

                            Text(viewModel.loggedInEmail.isEmpty ? "user@example.com" : viewModel.loggedInEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)

                        Spacer()
                    }
                }

                Section("Municipality of Residence") {
                    if let municipality = municipalityManager.selectedMunicipality {
                        HStack(spacing: 12) {
                            RemoteImageView(
                                urlString: municipality.displayLogoUrl,
                                fallbackSystemName: "building.2.crop.circle.fill",
                                size: 44,
                                shape: .roundedRectangle(cornerRadius: 10),
                                fallbackColor: .blue
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(municipality.name)
                                    .font(.headline)

                                Text(municipality.province)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Change") {
                                showingMunicipalitySheet = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 2)
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No Municipality Selected")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Select your city to filter election candidates.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Select") {
                                showingMunicipalitySheet = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }

                Section("Candidate Selections") {
                    LabeledContent("Total Saved Selections") {
                        Text("\(selectionsViewModel.selections.count)")
                            .bold()
                            .foregroundStyle(.blue)
                    }

                    if let municipality = municipalityManager.selectedMunicipality {
                        LabeledContent("Selections for \(municipality.name)") {
                            Text("\(selectionsViewModel.filteredSelections(for: municipality.name).count)")
                                .bold()
                        }
                    }

                    LabeledContent("Last Synchronized") {
                        if let syncDate = selectionsViewModel.lastSyncTimestamp {
                            Text(syncDate.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Not yet synchronized")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Account Details
                Section("Account Details") {
                    LabeledContent("Name", value: viewModel.loggedInName.isEmpty ? "Voter" : viewModel.loggedInName)
                    LabeledContent("Email", value: viewModel.loggedInEmail.isEmpty ? "Not available" : viewModel.loggedInEmail)
                }

                // Logout Action
                Section {
                    Button(role: .destructive) {
                        municipalityManager.resetForLogout()
                        viewModel.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingMunicipalitySheet) {
                MunicipalitySelectionView(isMandatory: false)
            }
            .task {
                selectionsViewModel.setUserEmail(viewModel.loggedInEmail)
            }
        }
    }
}

#Preview {
    ProfileView(viewModel: AuthViewModel())
        .environmentObject(CandidateSelectionsViewModel())
}
