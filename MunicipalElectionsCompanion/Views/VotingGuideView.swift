
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
                                    Task {
                                            await votingGuide.removeCandidate(candidate)
                                        }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Voting Guide")
            .task {
                await votingGuide.loadSavedCandidates()
            }
        }
    }

    private func positionName(for candidate: Candidate) -> String {
        candidate.positionName ?? "Unknown Position"
    }

    private func municipalityName(for candidate: Candidate) -> String {
        candidate.municipalityName ?? "Unknown Municipality"
    }
}

#Preview {
    VotingGuideView()
        .environmentObject(VotingGuideViewModel())
}
