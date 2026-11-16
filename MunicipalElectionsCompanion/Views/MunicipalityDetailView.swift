//
//  MunicipalityDetailView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct MunicipalityDetailView: View {
    let municipality: Municipality

    @State private var positions: [Position] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        List {
            // Municipality Header with Remote Logo
            Section {
                HStack(spacing: 16) {
                    RemoteImageView(
                        urlString: municipality.logoUrl,
                        fallbackSystemName: "building.2.crop.circle",
                        size: 72,
                        shape: .roundedRectangle(cornerRadius: 14),
                        fallbackColor: .blue
                    )

                    VStack(alignment: .leading, spacing: 5) {
                        Text(municipality.name)
                            .font(.title2)
                            .bold()

                        Text(municipality.province)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label(
                            municipality.electionDate.formatted(date: .long, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Municipality Information") {
                LabeledContent("Name", value: municipality.name)
                LabeledContent("Province", value: municipality.province)

                LabeledContent("Election Date") {
                    Text(municipality.electionDate, style: .date)
                }
            }

            if let description = municipality.description,
               !description.isEmpty {
                Section("Description") {
                    Text(description)
                        .font(.body)
                }
            }

            Section("Available Positions") {
                if isLoading {
                    ProgressView("Loading positions...")
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if positions.isEmpty {
                    Text("No positions available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(positions) { position in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(position.name)
                                .font(.headline)

                            Text("Seats available: \(position.seatsAvailable)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(municipality.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPositions()
        }
    }

    private func loadPositions() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let allPositions: [Position] = try await APIService.shared.get(
                "/api/positions"
            )

            positions = allPositions.filter {
                $0.municipalityId == municipality.municipalityId
            }
        } catch {
            errorMessage = "Failed to load positions."
            print("Positions API error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        MunicipalityDetailView(
            municipality: Municipality(
                municipalityId: 1,
                name: "Burnaby",
                province: "BC",
                electionDate: Date(),
                description: "City of Burnaby local municipal election.",
                logoUrl: "https://example.com/burnaby.png"
            )
        )
    }
}
