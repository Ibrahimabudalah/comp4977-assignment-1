//
//  CandidateListView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct CandidateListView: View {
    @StateObject private var viewModel = CandidateViewModel()
    @ObservedObject var municipalityManager = MunicipalityManager.shared
    @State private var showingMunicipalityPicker = false

    var body: some View {
        List {
            // Prominent City Header Banner (Assignment 2 Requirement)
            Section {
                HStack(spacing: 12) {
                    if let municipality = municipalityManager.selectedMunicipality {
                        RemoteImageView(
                            urlString: municipality.logoUrl,
                            fallbackSystemName: "building.2.crop.circle.fill",
                            size: 46,
                            shape: .roundedRectangle(cornerRadius: 10),
                            fallbackColor: .blue
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Active Municipality")
                                .font(.caption)
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)

                            Text(municipality.name)
                                .font(.title3)
                                .bold()

                            Text("Election: \(municipality.electionDate, style: .date)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            showingMunicipalityPicker = true
                        } label: {
                            Text("Change")
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    } else {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("No City Configured")
                                .font(.headline)
                            Text("Tap to select your municipality")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Select") {
                            showingMunicipalityPicker = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }

            // Position Filter Section
            if !viewModel.positions.isEmpty {
                Section("Filter by Office") {
                    Picker("Position", selection: $viewModel.selectedPosition) {
                        Text("All Positions (\(viewModel.candidates.count))").tag(0)

                        ForEach(viewModel.positions) { position in
                            Text("\(position.name) (\(position.seatsAvailable) seats)")
                                .tag(position.positionId)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Candidate List Section
            Section {
                if viewModel.isLoading && viewModel.candidates.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading candidates...")
                        Spacer()
                    }
                    .padding()
                } else {
                    ForEach(viewModel.filteredCandidates) { candidate in
                        NavigationLink {
                            CandidateDetailView(candidate: candidate)
                        } label: {
                            HStack(spacing: 14) {
                                // Candidate Remote Photo with Fallback
                                RemoteImageView(
                                    urlString: candidate.photoUrl,
                                    fallbackSystemName: "person.crop.circle.fill",
                                    size: 54,
                                    shape: .circle,
                                    fallbackColor: .blue
                                )

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(candidate.name)
                                        .font(.headline)

                                    Text(candidate.positionName ?? viewModel.positionName(for: candidate.positionId))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text(candidate.municipalityName ?? viewModel.municipalityName(for: candidate.municipalityId))
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            } header: {
                Text("Candidates (\(viewModel.filteredCandidates.count))")
            }
        }
        .navigationTitle(
            municipalityManager.selectedMunicipality != nil
                ? "City: \(municipalityManager.selectedMunicipality!.name)"
                : "Candidates"
        )
        .searchable(
            text: $viewModel.searchText,
            prompt: "Search candidates by name"
        )
        .refreshable {
            await reloadData()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingMunicipalityPicker = true
                } label: {
                    Image(systemName: "building.2")
                }
                .accessibilityLabel("Change Municipality")
            }
        }
        .sheet(isPresented: $showingMunicipalityPicker) {
            MunicipalitySelectionView(isMandatory: false)
        }
        .onChange(of: municipalityManager.selectedMunicipality?.municipalityId) {
            Task {
                await reloadData()
            }
        }
        .overlay {
            if !viewModel.isLoading && viewModel.filteredCandidates.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .task {
            await reloadData()
        }
    }

    private func reloadData() async {
        let cityId = municipalityManager.selectedMunicipality?.municipalityId
        await viewModel.loadData(for: cityId)
    }
}

#Preview {
    NavigationStack {
        CandidateListView()
    }
}
