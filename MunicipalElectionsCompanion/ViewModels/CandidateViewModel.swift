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
            candidates = []
            positions = []
            errorMessage = ""
            return
        }

        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            async let loadedMunicipalities: [Municipality] = APIService.shared.get("/api/municipalities")
            async let loadedPositions: [Position] = APIService.shared.get("/api/positions?municipalityId=\(municipalityId)")
            async let loadedCandidates: [Candidate] = APIService.shared.get("/api/candidates?municipalityId=\(municipalityId)")

            let (muns, pos, cands) = try await (loadedMunicipalities, loadedPositions, loadedCandidates)

            self.municipalities = muns
            self.positions = pos
            self.candidates = cands
        } catch {
            errorMessage = "Failed to load candidate information. Please check your connection."
            print("Failed to load candidates: \(error.localizedDescription)")
        }
    }

    func positionName(for positionId: Int) -> String {
        positions.first { $0.positionId == positionId }?.name ?? "Unknown Position"
    }

    func municipalityName(for municipalityId: Int) -> String {
        municipalities.first { $0.municipalityId == municipalityId }?.name ?? "Unknown Municipality"
    }
}
