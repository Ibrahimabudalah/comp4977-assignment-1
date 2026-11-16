//
//  VotingGuideView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

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
                                HStack(spacing: 14) {
                                    // Remote Candidate Photo with Fallback
                                    RemoteImageView(
                                        urlString: candidate.photoUrl,
                                        fallbackSystemName: "person.crop.circle.fill",
                                        size: 48,
                                        shape: .circle,
                                        fallbackColor: .blue
                                    )

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(candidate.name)
                                            .font(.headline)

                                        Text(positionName(for: candidate))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        Text(municipalityName(for: candidate))
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
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
            .refreshable {
                await votingGuide.loadSavedCandidates()
            }
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
