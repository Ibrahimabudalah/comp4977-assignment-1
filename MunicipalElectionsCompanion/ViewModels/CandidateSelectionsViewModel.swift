//
//  CandidateSelectionsViewModel.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-11-15.
//

import Foundation
import Combine

@MainActor
final class CandidateSelectionsViewModel: ObservableObject {
    @Published var selections: [CandidateSelection] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var lastSyncTimestamp: Date? = nil

    private var currentUserEmail: String = ""

    private var storageKey: String {
        guard !currentUserEmail.isEmpty else { return "candidate_selections_cache" }
        return "candidate_selections_\(currentUserEmail)"
    }

    private var syncTimestampKey: String {
        guard !currentUserEmail.isEmpty else { return "last_sync_timestamp" }
        return "last_sync_timestamp_\(currentUserEmail)"
    }

    init() {
        loadFromCache()
    }

    func setUserEmail(_ email: String) {
        let clean = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean != currentUserEmail else { return }
        self.currentUserEmail = clean
        loadFromCache()
    }


    func filteredSelections(for municipalityName: String?) -> [CandidateSelection] {
        guard let municipalityName, !municipalityName.isEmpty else {
            return selections
        }
        return selections.filter {
            $0.municipalityName.localizedCaseInsensitiveContains(municipalityName)
        }
    }

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


    func loadSelections() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Local read & prepare for firebase sync
        loadFromCache()
        lastSyncTimestamp = Date()
        UserDefaults.standard.set(lastSyncTimestamp, forKey: syncTimestampKey)
    }

    func createSelection(
        candidate: Candidate,
        notes: String,
        availablePositions: [Position]
    ) -> (success: Bool, message: String?) {
        // Enforce notes max length
        let trimmedNotes = String(notes.prefix(500))

        // Enforce duplicate rules
        let validation = validateCanSelect(candidate, availablePositions: availablePositions)
        guard validation.canAdd else {
            return (false, validation.message)
        }

        let newSelection = CandidateSelection(
            userEmail: currentUserEmail,
            candidateId: candidate.candidateId,
            candidateName: candidate.name,
            positionName: candidate.positionName ?? "Candidate",
            municipalityName: candidate.municipalityName ?? "",
            photoUrl: candidate.photoUrl,
            notes: trimmedNotes,
            dateCreated: Date(),
            dateModified: Date()
        )

        selections.insert(newSelection, at: 0)
        saveToCache()
        lastSyncTimestamp = Date()
        UserDefaults.standard.set(lastSyncTimestamp, forKey: syncTimestampKey)

        return (true, nil)
    }

    func updateSelection(selectionId: String, notes: String) -> Bool {
        guard let index = selections.firstIndex(where: { $0.id == selectionId }) else {
            return false
        }

        let trimmedNotes = String(notes.prefix(500))
        var updated = selections[index]
        updated.notes = trimmedNotes
        updated.dateModified = Date()

        selections[index] = updated
        saveToCache()
        lastSyncTimestamp = Date()
        UserDefaults.standard.set(lastSyncTimestamp, forKey: syncTimestampKey)

        return true
    }

    func deleteSelection(selectionId: String) -> Bool {
        guard let index = selections.firstIndex(where: { $0.id == selectionId }) else {
            return false
        }

        selections.remove(at: index)
        saveToCache()
        lastSyncTimestamp = Date()
        UserDefaults.standard.set(lastSyncTimestamp, forKey: syncTimestampKey)

        return true
    }

    func clearSelections() {
        selections.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: syncTimestampKey)
        lastSyncTimestamp = nil
    }


    private func saveToCache() {
        guard let encoded = try? JSONEncoder().encode(selections) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
        UserDefaults.standard.synchronize()
    }

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CandidateSelection].self, from: data) else {
            selections = []
            return
        }
        self.selections = decoded

        if let savedDate = UserDefaults.standard.object(forKey: syncTimestampKey) as? Date {
            self.lastSyncTimestamp = savedDate
        }
    }
}
