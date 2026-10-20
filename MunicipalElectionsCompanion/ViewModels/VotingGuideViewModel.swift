
import Foundation
import Combine

@MainActor
class VotingGuideViewModel: ObservableObject {
    @Published private(set) var savedCandidates: [Candidate] = []

    func addCandidate(_ candidate: Candidate) {
        guard !isSaved(candidate) else { return }
        savedCandidates.append(candidate)
    }

    func removeCandidate(_ candidate: Candidate) {
        savedCandidates.removeAll {
            $0.candidateId == candidate.candidateId
        }
    }

    func isSaved(_ candidate: Candidate) -> Bool {
        savedCandidates.contains {
            $0.candidateId == candidate.candidateId
        }
    }
}
