
import Foundation
import Combine

@MainActor
class VotingGuideViewModel: ObservableObject {
    @Published private(set) var savedCandidates: [Candidate] = []
    @Published var errorMessage = ""
    @Published var isLoading = false

    private var savedRecords: [SavedCandidate] = []

    func loadSavedCandidates() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let records: [SavedCandidate] = try await APIService.shared.get(
                "/api/savedcandidates"
            )

            savedRecords = records
            savedCandidates = records.compactMap { $0.candidate }
            
            print("Saved records from Azure: \(records.count)")
            print("Candidates available to display: \(savedCandidates.count)")

            print("Loaded \(savedCandidates.count) saved candidates from Azure")
        } catch {
            errorMessage = "Failed to load voting guide."
            print("Voting guide error: \(error.localizedDescription)")
        }
    }

    func addCandidate(_ candidate: Candidate) async {
        guard !isSaved(candidate) else { return }

        do {
            let request = SaveCandidateRequest(
                candidateId: candidate.candidateId
            )

            let record: SavedCandidate = try await APIService.shared.post(
                "/api/savedcandidates",
                body: request
            )

            savedRecords.append(record)
            savedCandidates.append(candidate)

            print("Candidate saved to Azure")
        } catch {
            errorMessage = "Failed to save candidate."
            print("Save candidate error: \(error.localizedDescription)")
        }
    }

    func removeCandidate(_ candidate: Candidate) async {
        guard let record = savedRecords.first(where: {
            $0.candidateId == candidate.candidateId
        }) else {
            return
        }

        do {
            try await APIService.shared.delete(
                "/api/savedcandidates/\(record.savedCandidateId)"
            )

            savedRecords.removeAll {
                $0.candidateId == candidate.candidateId
            }

            savedCandidates.removeAll {
                $0.candidateId == candidate.candidateId
            }

            print("Candidate removed from Azure")
        } catch {
            errorMessage = "Failed to remove candidate."
            print("Remove candidate error: \(error.localizedDescription)")
        }
    }

    func clearVotingGuide() {
        savedRecords.removeAll()
        savedCandidates.removeAll()
        errorMessage = ""
    }

    func isSaved(_ candidate: Candidate) -> Bool {
        savedCandidates.contains {
            $0.candidateId == candidate.candidateId
        }
    }
}
