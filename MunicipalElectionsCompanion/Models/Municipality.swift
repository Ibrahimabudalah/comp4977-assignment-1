
import Foundation

struct Municipality: Identifiable, Codable {
    let municipalityId: Int
    let name: String
    let province: String
    let electionDate: Date
    let description: String?
    let logoUrl: String?

    var id: Int { municipalityId }

    var displayLogoUrl: String? {
        if let logoUrl, !logoUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return logoUrl
        }

        switch name.lowercased() {
        case let n where n.contains("burnaby"):
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Flag_of_Burnaby%2C_British_Columbia.svg/320px-Flag_of_Burnaby%2C_British_Columbia.svg.png"
        case let n where n.contains("maple ridge"):
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Flag_of_Maple_Ridge%2C_British_Columbia.svg/320px-Flag_of_Maple_Ridge%2C_British_Columbia.svg.png"
        case let n where n.contains("pitt meadows"):
            return "https://upload.wikimedia.org/wikipedia/en/thumb/0/05/City_of_Pitt_Meadows_logo.png/300px-City_of_Pitt_Meadows_logo.png"
        default:
            return nil
        }
    }
}
