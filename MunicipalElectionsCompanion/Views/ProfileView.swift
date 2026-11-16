//
//  ProfileView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var votingGuide: VotingGuideViewModel
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

                // Configured Municipality Section (Assignment 2 Requirement)
                Section("Municipality of Residence") {
                    if let municipality = municipalityManager.selectedMunicipality {
                        HStack(spacing: 12) {
                            RemoteImageView(
                                urlString: municipality.logoUrl,
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

                // Account Information
                Section("Account Details") {
                    LabeledContent("Name", value: viewModel.loggedInName.isEmpty ? "Voter" : viewModel.loggedInName)
                    LabeledContent("Email", value: viewModel.loggedInEmail.isEmpty ? "Not available" : viewModel.loggedInEmail)
                }

                // Logout Action
                Section {
                    Button(role: .destructive) {
                        votingGuide.clearVotingGuide()
                        municipalityManager.clearSelection()
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
        }
    }
}

#Preview {
    ProfileView(viewModel: AuthViewModel())
        .environmentObject(VotingGuideViewModel())
}
