//
//  MunicipalityManager.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-11-15.
//

import Foundation
import Combine

@MainActor
final class MunicipalityManager: ObservableObject {
    static let shared = MunicipalityManager()

    private let selectedIdKey = "saved_selected_municipality_id"
    private var currentUserEmail: String = ""

    @Published var selectedMunicipality: Municipality? {
        didSet {
            if let selectedMunicipality {
                saveSelectedId(selectedMunicipality.municipalityId)
            }
        }
    }

    @Published var savedMunicipalityId: Int = 0
    @Published var availableMunicipalities: [Municipality] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    var hasSelectedMunicipality: Bool {
        selectedMunicipality != nil || savedMunicipalityId > 0
    }

    init() {
        loadSavedId()
    }

    private var userKey: String {
        if currentUserEmail.isEmpty {
            return selectedIdKey
        }
        return "\(selectedIdKey)_\(currentUserEmail)"
    }

    func setUserEmail(_ email: String) {
        let clean = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean != currentUserEmail else { return }
        self.currentUserEmail = clean
        loadSavedId()

        // If municipalities already loaded, resolve immediately
        if !availableMunicipalities.isEmpty && savedMunicipalityId > 0 {
            self.selectedMunicipality = availableMunicipalities.first { $0.municipalityId == savedMunicipalityId }
        }
    }

    func loadAvailableMunicipalities() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let loaded: [Municipality] = try await APIService.shared.get("/api/municipalities")
            self.availableMunicipalities = loaded

            // Match saved municipality ID to loaded object
            if savedMunicipalityId > 0 {
                if let matched = loaded.first(where: { $0.municipalityId == savedMunicipalityId }) {
                    self.selectedMunicipality = matched
                }
            } else if let current = selectedMunicipality {
                self.savedMunicipalityId = current.municipalityId
                saveSelectedId(current.municipalityId)
            }
        } catch {
            errorMessage = "Failed to load municipalities list."
            print("MunicipalityManager error: \(error.localizedDescription)")
        }
    }

    func selectMunicipality(_ municipality: Municipality) {
        self.savedMunicipalityId = municipality.municipalityId
        self.selectedMunicipality = municipality
        saveSelectedId(municipality.municipalityId)
    }

    func resetForLogout() {
        // Keep the saved ID in UserDefaults so user is remembered upon next login
        self.selectedMunicipality = nil
        self.currentUserEmail = ""
    }

    private func saveSelectedId(_ id: Int) {
        UserDefaults.standard.set(id, forKey: userKey)
        UserDefaults.standard.set(id, forKey: selectedIdKey)
        UserDefaults.standard.synchronize()
    }

    private func loadSavedId() {
        let idFromUserKey = UserDefaults.standard.integer(forKey: userKey)
        if idFromUserKey > 0 {
            self.savedMunicipalityId = idFromUserKey
        } else {
            self.savedMunicipalityId = UserDefaults.standard.integer(forKey: selectedIdKey)
        }

        if !availableMunicipalities.isEmpty && savedMunicipalityId > 0 {
            self.selectedMunicipality = availableMunicipalities.first { $0.municipalityId == savedMunicipalityId }
        }
    }
}
