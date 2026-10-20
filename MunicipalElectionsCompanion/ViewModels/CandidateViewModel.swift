
import Foundation
import Combine

@MainActor
class CandidateViewModel: ObservableObject {
    @Published var candidates: [Candidate] = []
    @Published var searchText = ""
    @Published var selectedMunicipality = 0
    @Published var selectedPosition = 0

    var filteredCandidates: [Candidate] {
        candidates.filter { candidate in
            let matchesSearch = searchText.isEmpty ||
                candidate.name.localizedCaseInsensitiveContains(searchText)

            let matchesMunicipality = selectedMunicipality == 0 ||
                candidate.municipalityId == selectedMunicipality

            let matchesPosition = selectedPosition == 0 ||
                candidate.positionId == selectedPosition

            return matchesSearch &&
                   matchesMunicipality &&
                   matchesPosition
        }
    }

    func loadCandidates() {
        candidates = MockData.candidates
    }

    func positionName(for candidate: Candidate) -> String {
        MockData.positions.first {
            $0.positionId == candidate.positionId
        }?.name ?? "Unknown Position"
    }

    func municipalityName(for candidate: Candidate) -> String {
        MockData.municipalities.first {
            $0.municipalityId == candidate.municipalityId
        }?.name ?? "Unknown Municipality"
    }
}
