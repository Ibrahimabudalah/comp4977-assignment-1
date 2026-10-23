
import SwiftUI

struct CandidateListView: View {
    @StateObject private var viewModel = CandidateViewModel()

    private var availablePositions: [Position] {
        if viewModel.selectedMunicipality == 0 {
            return viewModel.positions
        }

        return viewModel.positions.filter {
            $0.municipalityId == viewModel.selectedMunicipality
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Municipality", selection: $viewModel.selectedMunicipality) {
                    Text("All Municipalities").tag(0)

                    ForEach(viewModel.municipalities) { municipality in
                        Text(municipality.name)
                            .tag(municipality.municipalityId)
                    }
                }

                Picker("Position", selection: $viewModel.selectedPosition) {
                    Text("All Positions").tag(0)

                    ForEach(availablePositions) { position in
                        Text("\(position.name) - \(municipalityName(for: position))")
                            .tag(position.positionId)
                    }
                }
            } header: {
                Text("Filters")
            }

            Section {
                ForEach(viewModel.filteredCandidates) { candidate in
                    NavigationLink {
                        CandidateDetailView(candidate: candidate)
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.blue)
                                .frame(width: 55, height: 55)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(candidate.name)
                                    .font(.headline)

                                Text(viewModel.positionName(for: candidate.positionId))
                                    .font(.subheadline)

                                Text(viewModel.municipalityName(for: candidate.municipalityId))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            } header: {
                Text("Candidates (\(viewModel.filteredCandidates.count))")
            }
        }
        .navigationTitle("Candidates")
        .searchable(
            text: $viewModel.searchText,
            prompt: "Search candidates"
        )
        .onChange(of: viewModel.selectedMunicipality) {
            viewModel.selectedPosition = 0
        }
        .overlay {
            if viewModel.filteredCandidates.isEmpty {
                ContentUnavailableView.search(
                    text: viewModel.searchText
                )
            }
        }
        .task {
            await viewModel.loadFilterData()
            await viewModel.loadCandidates()
        }
    }

    private func municipalityName(for position: Position) -> String {
        viewModel.municipalities.first {
            $0.municipalityId == position.municipalityId
        }?.name ?? ""
    }
}

#Preview {
    NavigationStack {
        CandidateListView()
    }
}
