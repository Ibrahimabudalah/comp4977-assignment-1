
import Foundation

struct SavedCandidate: Identifiable, Codable {
    let savedCandidateId: Int
    let userId: String
    let candidateId: Int
    let dateSaved: Date
    let candidate: Candidate?

    var id: Int { savedCandidateId }
}
