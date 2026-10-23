
import Foundation
import Combine

@MainActor
class MunicipalityViewModel: ObservableObject {
    @Published var municipalities: [Municipality] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadMunicipalities() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            municipalities = try await APIService.shared.get(
                "/api/municipalities"
            )

            print("Loaded \(municipalities.count) municipalities from Azure")
        } catch {
            municipalities = []
            errorMessage = "Failed to load municipalities. Please try again."

            print("Municipalities API failed: \(error.localizedDescription)")
        }
    }
}
