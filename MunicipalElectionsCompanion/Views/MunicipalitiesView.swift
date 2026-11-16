//
//  MunicipalitiesView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct MunicipalitiesView: View {
    @StateObject private var viewModel = MunicipalityViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.municipalities) { municipality in
                NavigationLink {
                    MunicipalityDetailView(municipality: municipality)
                } label: {
                    HStack(spacing: 15) {
                        // Remote Municipality Logo with Fallback
                        RemoteImageView(
                            urlString: municipality.logoUrl,
                            fallbackSystemName: "building.2.crop.circle",
                            size: 48,
                            shape: .roundedRectangle(cornerRadius: 10),
                            fallbackColor: .blue
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(municipality.name)
                                .font(.headline)

                            Text(municipality.province)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(
                                municipality.electionDate,
                                style: .date
                            )
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Municipalities")
            .refreshable {
                await viewModel.loadMunicipalities()
            }
            .overlay {
                if viewModel.isLoading && viewModel.municipalities.isEmpty {
                    ProgressView("Loading municipalities...")
                }
            }
            .task {
                await viewModel.loadMunicipalities()
            }
        }
    }
}

#Preview {
    MunicipalitiesView()
}
