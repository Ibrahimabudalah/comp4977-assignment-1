
import Foundation
import Combine

@MainActor
class CandidateViewModel: ObservableObject {
    @Published var candidates: [Candidate] = []

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
