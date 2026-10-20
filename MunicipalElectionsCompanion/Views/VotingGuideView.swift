
import SwiftUI

struct VotingGuideView: View {
    @EnvironmentObject var votingGuide: VotingGuideViewModel

    var body: some View {
        NavigationStack {
            Group {
                if votingGuide.savedCandidates.isEmpty {
                    ContentUnavailableView(
                        "No Saved Candidates",
                        systemImage: "bookmark",
                        description: Text(
                            "Candidates you save will appear here."
                        )
                    )
                } else {
                    List {
                        ForEach(votingGuide.savedCandidates) { candidate in
                            NavigationLink {
                                CandidateDetailView(candidate: candidate)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.blue)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(candidate.name)
                                            .font(.headline)

                                        Text(positionName(for: candidate))
                                            .font(.subheadline)

                                        Text(municipalityName(for: candidate))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    votingGuide.removeCandidate(candidate)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Voting Guide")
        }
    }

    private func positionName(for candidate: Candidate) -> String {
        MockData.positions.first {
            $0.positionId == candidate.positionId
        }?.name ?? "Unknown Position"
    }

    private func municipalityName(for candidate: Candidate) -> String {
        MockData.municipalities.first {
            $0.municipalityId == candidate.municipalityId
        }?.name ?? "Unknown Municipality"
    }
}

#Preview {
    VotingGuideView()
        .environmentObject(VotingGuideViewModel())
}
