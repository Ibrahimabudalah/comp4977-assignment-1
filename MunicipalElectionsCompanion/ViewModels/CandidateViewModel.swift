//
//  CandidateViewModel.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import Foundation
import Combine

@MainActor
class CandidateViewModel: ObservableObject {
    @Published var candidates: [Candidate] = []
    @Published var positions: [Position] = []
    @Published var municipalities: [Municipality] = []

    @Published var searchText = ""
    @Published var selectedPosition = 0

    @Published var isLoading = false
    @Published var errorMessage = ""

    /// City the current lists belong to; lets us clear them (and the office filter) when it changes.
    private var loadedMunicipalityId: Int?
    /// Bumped per load so a superseded load can't overwrite the newer one's results or spinner.
    private var loadGeneration = 0

    var filteredCandidates: [Candidate] {
        candidates.filter { candidate in
            let matchesSearch = searchText.isEmpty ||
                candidate.name.localizedCaseInsensitiveContains(searchText)

            let matchesPosition = selectedPosition == 0 ||
                candidate.positionId == selectedPosition

            return matchesSearch && matchesPosition
        }
    }

    /// Loads election data for one municipality only. With no municipality selected
    /// nothing is loaded, so data from other cities can never reach the UI.
    func loadData(for municipalityId: Int?) async {
        guard let municipalityId, municipalityId > 0 else {
            loadGeneration += 1 // invalidate any load still in flight
            clearLists()
            loadedMunicipalityId = nil
            errorMessage = ""
            return
        }

        // Position ids are per city, so a new city must not keep the old city's lists or office filter.
        if municipalityId != loadedMunicipalityId {
            clearLists()
            loadedMunicipalityId = municipalityId
        }

        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        errorMessage = ""
        defer { if generation == loadGeneration { isLoading = false } }

        do {
            async let loadedMunicipalities: [Municipality] = APIService.shared.get("/api/municipalities")
            async let loadedPositions: [Position] = APIService.shared.get("/api/positions?municipalityId=\(municipalityId)")
            async let loadedCandidates: [Candidate] = APIService.shared.get("/api/candidates?municipalityId=\(municipalityId)")

            let (muns, pos, cands) = try await (loadedMunicipalities, loadedPositions, loadedCandidates)
            // Drop a stale response (newer load started, or this one was cancelled) instead of showing it.
            guard generation == loadGeneration, !Task.isCancelled else { return }

            self.municipalities = muns
            self.positions = pos
            self.candidates = cands
        } catch {
            guard generation == loadGeneration, !Task.isCancelled else { return }
            errorMessage = "Failed to load candidate information. Please check your connection."
            print("Failed to load candidates: \(error.localizedDescription)")
        }
    }

    private func clearLists() {
        candidates = []
        positions = []
        selectedPosition = 0
    }

    func positionName(for positionId: Int) -> String {
        positions.first { $0.positionId == positionId }?.name ?? "Unknown Position"
    }

    func municipalityName(for municipalityId: Int) -> String {
        municipalities.first { $0.municipalityId == municipalityId }?.name ?? "Unknown Municipality"
    }
}
