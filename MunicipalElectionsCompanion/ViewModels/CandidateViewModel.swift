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

    func loadData(for municipalityId: Int? = nil) async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            async let loadedMunicipalities: [Municipality] = APIService.shared.get("/api/municipalities")

            let positionsEndpoint: String
            let candidatesEndpoint: String

            if let municipalityId, municipalityId > 0 {
                positionsEndpoint = "/api/positions?municipalityId=\(municipalityId)"
                candidatesEndpoint = "/api/candidates?municipalityId=\(municipalityId)"
            } else {
                positionsEndpoint = "/api/positions"
                candidatesEndpoint = "/api/candidates"
            }

            async let loadedPositions: [Position] = APIService.shared.get(positionsEndpoint)
            async let loadedCandidates: [Candidate] = APIService.shared.get(candidatesEndpoint)

            let (muns, pos, cands) = try await (loadedMunicipalities, loadedPositions, loadedCandidates)

            self.municipalities = muns
            self.positions = pos
            self.candidates = cands

            print("Loaded \(cands.count) candidates and \(pos.count) positions for municipality \(municipalityId ?? 0)")
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
