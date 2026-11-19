//
//  CandidateSelectionsViewModel.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-11-15.
//
//  Selections live in Firestore (CandidateSelections). `start` attaches a live listener scoped to one
//  user and one municipality, so only that user's records for that city ever reach the screen.
//

import Foundation
import Combine

@MainActor
final class CandidateSelectionsViewModel: ObservableObject {
    /// `message` is set on failure, and also on success when a write could only be queued offline.
    typealias ActionResult = (success: Bool, message: String?)

    @Published var selections: [CandidateSelection] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var lastSyncTimestamp: Date? = nil

    private var currentUserEmail = ""
    private var currentMunicipalityId = 0
    private var stopListening: (() -> Void)?
    /// Bumped on every start/stop so a late callback from an old listener or fetch is ignored.
    private var generation = 0

    // MARK: - Listener lifecycle

    /// Starts listening to `email`'s selections in one municipality, replacing any previous listener.
    func start(email: String, municipalityId: Int) {
        stop()

        let email = FirebaseService.normalize(email)
        guard !email.isEmpty, municipalityId > 0 else { return }

        currentUserEmail = email
        currentMunicipalityId = municipalityId
        isLoading = true

        let listenerGeneration = generation
        stopListening = FirebaseService.shared.listenToSelections(
            email: email,
            municipalityId: municipalityId
        ) { [weak self] result in
            guard let self, listenerGeneration == self.generation else { return }
            self.apply(result)
        }
    }

    /// Stops listening and clears everything (logout, or no municipality selected).
    func stop() {
        generation += 1
        stopListening?()
        stopListening = nil

        selections = []
        errorMessage = nil
        lastSyncTimestamp = nil
        isLoading = false
        currentUserEmail = ""
        currentMunicipalityId = 0
    }

    private func apply(_ result: Result<SelectionsSnapshot, Error>) {
        isLoading = false

        switch result {
        case .success(let snapshot):
            selections = snapshot.selections
            errorMessage = snapshot.skippedCount > 0 ? FirebaseService.unreadableSelectionsMessage : nil
            // A cached snapshot hasn't been confirmed by the server yet, so it isn't a sync
            if !snapshot.isFromCache {
                lastSyncTimestamp = Date()
            }
        case .failure(let error):
            errorMessage = FirebaseService.message(for: error)
        }
    }

    // MARK: - Queries

    func isCandidateSelected(_ candidateId: Int) -> Bool {
        selections.contains { $0.candidateId == candidateId }
    }

    func selection(for candidateId: Int) -> CandidateSelection? {
        selections.first { $0.candidateId == candidateId }
    }


    func validateCanSelect(
        _ candidate: Candidate,
        availablePositions: [Position]
    ) -> (canAdd: Bool, message: String?) {
        // Duplicate check
        if isCandidateSelected(candidate.candidateId) {
            return (false, "\(candidate.name) is already in your candidate selections.")
        }

        // Seat limit check
        let position = availablePositions.first { $0.positionId == candidate.positionId }
        let seatsAllowed = position?.seatsAvailable ?? 1
        let posName = candidate.positionName ?? position?.name ?? "this position"
        let munName = candidate.municipalityName ?? ""

        let existingForPosition = selections.filter {
            $0.positionName.localizedCaseInsensitiveCompare(posName) == .orderedSame &&
            (munName.isEmpty || $0.municipalityName.localizedCaseInsensitiveCompare(munName) == .orderedSame)
        }.count

        if existingForPosition >= seatsAllowed {
            let officeLabel = "\(posName) (\(seatsAllowed) seat\(seatsAllowed > 1 ? "s" : ""))"
            return (
                false,
                "Maximum selection reached for \(officeLabel). You have already selected \(existingForPosition) candidate\(existingForPosition > 1 ? "s" : ""). Remove an existing selection to choose a different candidate."
            )
        }

        return (true, nil)
    }

    // MARK: - Actions

    /// Pull to refresh: an explicit read from the server.
    func loadSelections() async {
        guard !currentUserEmail.isEmpty, currentMunicipalityId > 0 else { return }

        let requestGeneration = generation
        do {
            let snapshot = try await FirebaseService.shared.fetchSelections(
                email: currentUserEmail,
                municipalityId: currentMunicipalityId
            )
            guard requestGeneration == generation else { return }
            apply(.success(snapshot))
        } catch {
            // A cancelled refresh (view left, city changed) isn't an error worth showing
            guard requestGeneration == generation, !Task.isCancelled else { return }
            errorMessage = FirebaseService.message(for: error)
        }
    }

    func createSelection(
        candidate: Candidate,
        notes: String,
        availablePositions: [Position]
    ) async -> ActionResult {
        if let blocked = blockedReason() { return (false, blocked) }

        // Required fields
        guard !candidate.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, "This candidate has no name and can't be saved.")
        }
        // A selection must belong to the municipality the user is viewing
        guard candidate.municipalityId == currentMunicipalityId else {
            return (false, "This candidate doesn't belong to your selected municipality.")
        }

        // Enforce duplicate and seat rules
        let validation = validateCanSelect(candidate, availablePositions: availablePositions)
        guard validation.canAdd else {
            return (false, validation.message)
        }

        let now = Date()
        let newSelection = CandidateSelection(
            id: FirebaseService.selectionId(email: currentUserEmail, candidateId: candidate.candidateId),
            userEmail: currentUserEmail,
            candidateId: candidate.candidateId,
            candidateName: candidate.name,
            positionName: candidate.positionName ?? "Candidate",
            municipalityId: candidate.municipalityId,
            municipalityName: candidate.municipalityName ?? "",
            photoUrl: candidate.photoUrl,
            notes: String(notes.prefix(500)),
            dateCreated: now,
            dateModified: now
        )

        return await perform { try await FirebaseService.shared.saveSelection(newSelection) }
    }

    func updateSelection(selectionId: String, notes: String) async -> ActionResult {
        if let blocked = blockedReason() { return (false, blocked) }

        guard var updated = selections.first(where: { $0.id == selectionId }) else {
            return (false, "That selection no longer exists.")
        }

        updated.notes = String(notes.prefix(500))
        updated.dateModified = Date()

        return await perform { try await FirebaseService.shared.saveSelection(updated) }
    }

    func deleteSelection(selectionId: String) async -> ActionResult {
        if let blocked = blockedReason() { return (false, blocked) }

        guard selections.contains(where: { $0.id == selectionId }) else {
            return (false, "That selection no longer exists.")
        }

        return await perform { try await FirebaseService.shared.deleteSelection(id: selectionId) }
    }

    // MARK: - Helpers

    /// Why a write can't go ahead right now, or nil when it can.
    private func blockedReason() -> String? {
        guard !currentUserEmail.isEmpty, currentMunicipalityId > 0 else {
            return "Please select your municipality first."
        }
        if TokenManager.shared.isTokenExpired() {
            return APIError.unauthorized.errorDescription
        }
        return nil
    }

    /// Runs a Firestore write. A write that only timed out waiting for the server is still queued by
    /// Firestore and syncs later, so it counts as saved but carries the offline notice.
    private func perform(_ write: () async throws -> Void) async -> ActionResult {
        do {
            try await write()
            return (true, nil)
        } catch FirebaseServiceError.writeTimedOut {
            return (true, FirebaseServiceError.writeTimedOut.errorDescription)
        } catch {
            return (false, FirebaseService.message(for: error))
        }
    }
}
