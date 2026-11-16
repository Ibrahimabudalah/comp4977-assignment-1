
import Foundation
import Combine

@MainActor
final class MunicipalityManager: ObservableObject {
    static let shared = MunicipalityManager()

    private let selectedMunicipalityKey = "selected_municipality_cache"

    @Published var selectedMunicipality: Municipality? {
        didSet {
            saveToStorage()
        }
    }

    @Published var availableMunicipalities: [Municipality] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    var hasSelectedMunicipality: Bool {
        selectedMunicipality != nil
    }

    init() {
        loadFromStorage()
    }

    func loadAvailableMunicipalities() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let loaded: [Municipality] = try await APIService.shared.get("/api/municipalities")
            self.availableMunicipalities = loaded

            // If we had a saved municipality, update it with fresh data if present
            if let current = selectedMunicipality,
               let updated = loaded.first(where: { $0.municipalityId == current.municipalityId }) {
                self.selectedMunicipality = updated
            }
        } catch {
            errorMessage = "Failed to load municipalities list."
            print("MunicipalityManager error: \(error.localizedDescription)")
        }
    }

    func selectMunicipality(_ municipality: Municipality) {
        self.selectedMunicipality = municipality
    }

    func clearSelection() {
        self.selectedMunicipality = nil
        UserDefaults.standard.removeObject(forKey: selectedMunicipalityKey)
    }

    private func saveToStorage() {
        guard let selectedMunicipality else {
            UserDefaults.standard.removeObject(forKey: selectedMunicipalityKey)
            return
        }

        if let encoded = try? JSONEncoder().encode(selectedMunicipality) {
            UserDefaults.standard.set(encoded, forKey: selectedMunicipalityKey)
        }
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: selectedMunicipalityKey),
              let decoded = try? JSONDecoder.api.decode(Municipality.self, from: data) else {
            return
        }
        self.selectedMunicipality = decoded
    }
}
