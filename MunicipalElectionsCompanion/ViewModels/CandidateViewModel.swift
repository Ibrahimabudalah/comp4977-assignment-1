
import Foundation
import Combine

@MainActor
class CandidateViewModel: ObservableObject {
    @Published var candidates: [Candidate] = []
    @Published var municipalities: [Municipality] = []
    @Published var positions: [Position] = []

    @Published var searchText = ""
    @Published var selectedMunicipality = 0
    @Published var selectedPosition = 0

    @Published var isLoading = false
    @Published var errorMessage = ""

    var filteredCandidates: [Candidate] {
        candidates.filter { candidate in
            let matchesSearch = searchText.isEmpty ||
                candidate.name.localizedCaseInsensitiveContains(searchText)

            let matchesMunicipality = selectedMunicipality == 0 ||
                candidate.municipalityId == selectedMunicipality

            let matchesPosition = selectedPosition == 0 ||
                candidate.positionId == selectedPosition

            return matchesSearch &&
                   matchesMunicipality &&
                   matchesPosition
        }
    }

    func loadCandidates() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            candidates = try await APIService.shared.get(
                "/api/candidates"
            )

            print("Loaded \(candidates.count) candidates from Azure")
        } catch {
            candidates = []
            errorMessage = "Failed to load candidates. Please try again."

            print("Failed to load candidates: \(error.localizedDescription)")
        }
    }

    func positionName(for positionId: Int) -> String {
        positions.first {
            $0.positionId == positionId
        }?.name ?? "Unknown Position"
    }

    func municipalityName(for municipalityId: Int) -> String {
        municipalities.first {
            $0.municipalityId == municipalityId
        }?.name ?? "Unknown Municipality"
    }

    func loadFilterData() async {
        do {
            async let municipalitiesRequest: [Municipality] =
                APIService.shared.get("/api/municipalities")

            async let positionsRequest: [Position] =
                APIService.shared.get("/api/positions")

            let (loadedMunicipalities, loadedPositions) =
                try await (municipalitiesRequest, positionsRequest)

            municipalities = loadedMunicipalities
            positions = loadedPositions

            print("Candidate filters loaded from Azure")
        } catch {
            municipalities = []
            positions = []
            errorMessage = "Failed to load candidate filters. Please try again."

            print("Filter loading failed: \(error.localizedDescription)")
        }
    }
}
