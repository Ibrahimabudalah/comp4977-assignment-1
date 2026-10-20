
import Foundation

struct Position: Identifiable, Codable {
    let positionId: Int
    let name: String
    let seatsAvailable: Int
    let municipalityId: Int

    var id: Int { positionId }
}
