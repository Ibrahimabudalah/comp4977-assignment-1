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
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var showingMunicipalityPicker = false

    // Adaptive orientation helpers
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var isPhoneLandscape: Bool {
        UIDevice.current.userInterfaceIdiom == .phone && verticalSizeClass == .compact
    }

    private var isGridMode: Bool {
        isIPad || isPhoneLandscape
    }

    // Dynamic grid columns based on device & orientation.
    // iPad uses an adaptive grid so the column count follows the width actually available
    // (with the sidebar open or closed, either orientation, any iPad size) instead of a fixed count.
    private var gridColumns: [GridItem] {
        if isIPad {
            return [GridItem(.adaptive(minimum: 260), spacing: 16)]
        } else if isPhoneLandscape {
            return [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        }
        return [GridItem(.flexible())]
    }

    var body: some View {
        Group {
            if isGridMode {
                // Adaptive Grid layout for iPad & iPhone Landscape
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        activeMunicipalityCard

                        if !viewModel.positions.isEmpty {
                            positionFilterBar
                        }

                        if viewModel.isLoading && viewModel.candidates.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView("Loading candidates...")
                                Spacer()
                            }
                            .padding(.vertical, 40)
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(viewModel.filteredCandidates) { candidate in
                                    NavigationLink {
                                        CandidateDetailView(
                                            candidate: candidate,
                                            availablePositions: viewModel.positions
                                        )
                                    } label: {
                                        candidateGridCard(for: candidate)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                // Scrolling layout for iPhone
                List {
                    Section {
                        activeMunicipalityCard
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

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
                                    CandidateDetailView(
                                        candidate: candidate,
                                        availablePositions: viewModel.positions
                                    )
                                } label: {
                                    candidateListRow(for: candidate)
                                }
                            }
                        }
                    } header: {
                        Text("Candidates (\(viewModel.filteredCandidates.count))")
                    }
                }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Spec Part 3 example: app name with the active city beneath it
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Municipal Elections Companion")
                        .font(.headline)
                    if let city = municipalityManager.selectedMunicipality?.name {
                        Text("City: \(city)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
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
        .overlay {
            if municipalityManager.selectedMunicipality != nil && !viewModel.isLoading && viewModel.filteredCandidates.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        // Runs on appear and again whenever the city changes; a newer load cancels the stale one.
        .task(id: municipalityManager.selectedMunicipality?.municipalityId) {
            await reloadData()
        }
    }

    private var activeMunicipalityCard: some View {
        HStack(spacing: 12) {
            if let municipality = municipalityManager.selectedMunicipality {
                RemoteImageView(
                    urlString: municipality.displayLogoUrl,
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
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var positionFilterBar: some View {
        HStack {
            Text("Filter by Office:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Position", selection: $viewModel.selectedPosition) {
                Text("All Positions (\(viewModel.candidates.count))").tag(0)

                ForEach(viewModel.positions) { position in
                    Text("\(position.name) (\(position.seatsAvailable) seats)")
                        .tag(position.positionId)
                }
            }
            .pickerStyle(.menu)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // Row for iPhone list
    private func candidateListRow(for candidate: Candidate) -> some View {
        HStack(spacing: 14) {
            RemoteImageView(
                urlString: candidate.photoUrl,
                initialsText: candidate.name,
                fallbackSystemName: "person.crop.circle.fill",
                size: 54,
                shape: .circle,
                fallbackColor: .blue
            )

            VStack(alignment: .leading, spacing: 4) {
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

    // Adaptive card for iPad & iPhone Landscape
    private func candidateGridCard(for candidate: Candidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RemoteImageView(
                    urlString: candidate.photoUrl,
                    initialsText: candidate.name,
                    fallbackSystemName: "person.crop.circle.fill",
                    size: 56,
                    shape: .circle,
                    fallbackColor: .blue
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(candidate.positionName ?? viewModel.positionName(for: candidate.positionId))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(candidate.municipalityName ?? viewModel.municipalityName(for: candidate.municipalityId))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let bio = candidate.biography, !bio.isEmpty {
                Text(bio)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(isPhoneLandscape ? 2 : 3)
                    .multilineTextAlignment(.leading)
            }

            // Contact indicators
            HStack(spacing: 10) {
                if candidate.website != nil {
                    Label("Web", systemImage: "globe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if candidate.email != nil {
                    Label("Email", systemImage: "envelope")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
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
