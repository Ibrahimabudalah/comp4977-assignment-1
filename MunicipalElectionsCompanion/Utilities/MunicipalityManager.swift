//
//  MunicipalityManager.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-11-15.
//
//  The user's selected municipality is stored in Firestore (UserProfiles/<email>) and loaded at login,
//  so it follows the user across devices and can never leak from one user to the next.
//

import Foundation
import Combine

@MainActor
final class MunicipalityManager: ObservableObject {
    static let shared = MunicipalityManager()

    @Published private(set) var selectedMunicipality: Municipality?
    @Published private(set) var availableMunicipalities: [Municipality] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String = ""
    /// True once the user's profile has been read from Firestore (even if it holds no city yet).
    @Published private(set) var profileLoaded = false

    private var currentUserEmail = ""
    private var savedMunicipalityId = 0
    /// Bumped by every restore and by logout, so a slow call for a previous user is ignored.
    private var restoreGeneration = 0

    /// First login (or a saved city that no longer exists): the user has to pick one.
    /// False while loading or when the profile couldn't be read, so a returning user offline is never
    /// asked to choose again (that would overwrite the city they already saved).
    var needsInitialSelection: Bool {
        profileLoaded && !availableMunicipalities.isEmpty && selectedMunicipality == nil
    }

    // MARK: - Loading

    /// Loads the user's saved municipality from Firestore and the municipality list from the API,
    /// then resolves the saved id to a city. Pass `email` at login; call with no argument to retry.
    func restore(forEmail email: String? = nil) async {
        if let email {
            let clean = FirebaseService.normalize(email)
            if clean != currentUserEmail {
                selectedMunicipality = nil
                savedMunicipalityId = 0
                profileLoaded = false
            }
            currentUserEmail = clean
        }
        guard !currentUserEmail.isEmpty else { return }

        restoreGeneration += 1
        let generation = restoreGeneration
        let userEmail = currentUserEmail

        isLoading = true
        errorMessage = ""
        defer { if generation == restoreGeneration { isLoading = false } }

        if !profileLoaded {
            do {
                let profile = try await FirebaseService.shared.getProfile(email: userEmail)
                guard generation == restoreGeneration else { return }
                savedMunicipalityId = profile?.municipalityId ?? 0
                profileLoaded = true
            } catch {
                guard generation == restoreGeneration, !Task.isCancelled else { return }
                errorMessage = "Couldn't load your saved municipality."
                print("MunicipalityManager profile error: \(error.localizedDescription)")
            }
        }

        do {
            let loaded: [Municipality] = try await APIService.shared.get("/api/municipalities")
            guard generation == restoreGeneration else { return }
            availableMunicipalities = loaded
        } catch {
            guard generation == restoreGeneration, !Task.isCancelled else { return }
            // Keep the profile error if there already is one: it is the more specific message
            if errorMessage.isEmpty { errorMessage = "Failed to load municipalities list." }
            print("MunicipalityManager error: \(error.localizedDescription)")
        }

        resolveSelectedMunicipality()
    }

    /// Just the municipality list, for the city picker.
    func loadAvailableMunicipalities() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            availableMunicipalities = try await APIService.shared.get("/api/municipalities")
            resolveSelectedMunicipality()
        } catch {
            errorMessage = "Failed to load municipalities list."
            print("MunicipalityManager error: \(error.localizedDescription)")
        }
    }

    // MARK: - Changing the municipality

    /// Saves the choice to Firestore first, then applies it, so the app and Firestore never disagree.
    /// Everything municipality-specific (candidates, offices, selections) reloads from the change.
    /// Throws if the save fails; the previous city then stays selected.
    func selectMunicipality(_ municipality: Municipality) async throws {
        guard !currentUserEmail.isEmpty else {
            assertionFailure("selectMunicipality called while logged out")
            return
        }

        do {
            try await FirebaseService.shared.saveProfile(
                email: currentUserEmail,
                municipalityId: municipality.municipalityId,
                municipalityName: municipality.name
            )
        } catch FirebaseServiceError.writeTimedOut {
            // Offline: Firestore keeps the write queued and syncs it later, so apply the choice now
        }

        savedMunicipalityId = municipality.municipalityId
        profileLoaded = true
        selectedMunicipality = municipality
    }

    func resetForLogout() {
        restoreGeneration += 1
        currentUserEmail = ""
        savedMunicipalityId = 0
        selectedMunicipality = nil
        profileLoaded = false
        errorMessage = ""
        isLoading = false
    }

    private func resolveSelectedMunicipality() {
        guard savedMunicipalityId > 0 else { return }
        selectedMunicipality = availableMunicipalities.first { $0.municipalityId == savedMunicipalityId }
    }
}
