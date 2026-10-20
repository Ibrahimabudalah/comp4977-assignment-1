
import Foundation
import Combine

@MainActor
class MunicipalityViewModel: ObservableObject {
    @Published var municipalities: [Municipality] = []

    func loadMunicipalities() {
        municipalities = MockData.municipalities
    }
}
