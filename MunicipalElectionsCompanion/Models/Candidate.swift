
import Foundation

struct Candidate: Identifiable, Codable {
    let candidateId: Int
    let name: String
    let biography: String?
    let photoUrl: String?
    let website: String?
    let email: String?
    let positionId: Int
    let municipalityId: Int
    let positionName: String?
    let municipalityName: String?

    var id: Int { candidateId }
}
