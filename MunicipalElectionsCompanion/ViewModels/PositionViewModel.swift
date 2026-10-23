
import Foundation
import Combine

@MainActor
class PositionViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadPositions() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            positions = try await APIService.shared.get(
                "/api/positions"
            )

            print("Loaded \(positions.count) positions from Azure")
        } catch {
            positions = []
            errorMessage = "Failed to load positions. Please try again."

            print("Positions API failed: \(error.localizedDescription)")
        }
    }
}
