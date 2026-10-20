
import Foundation

struct Municipality: Identifiable, Codable {
    let municipalityId: Int
    let name: String
    let province: String
    let electionDate: Date
    let description: String?
    let logoUrl: String?

    var id: Int { municipalityId }
}
