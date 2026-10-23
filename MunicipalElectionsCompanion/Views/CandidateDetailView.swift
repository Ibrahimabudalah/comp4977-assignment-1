
import SwiftUI

struct CandidateDetailView: View {
    let candidate: Candidate

    @EnvironmentObject var votingGuide: VotingGuideViewModel
    @State private var isUpdating = false

    private var positionName: String {
        candidate.positionName ?? "Unknown Position"
    }

    private var municipalityName: String {
        candidate.municipalityName ?? "Unknown Municipality"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Candidate photo
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)

                // Candidate name and position
                VStack(spacing: 5) {
                    Text(candidate.name)
                        .font(.title)
                        .bold()

                    Text("\(positionName) - \(municipalityName)")
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Biography
                VStack(alignment: .leading, spacing: 10) {
                    Text("Biography")
                        .font(.headline)

                    Text(candidate.biography ?? "No biography available.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Contact information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Information")
                        .font(.headline)

                    if let website = candidate.website,
                       let url = URL(string: website) {
                        Link(destination: url) {
                            Label("Visit Website", systemImage: "globe")
                        }
                    }

                    if let email = candidate.email,
                       let url = URL(string: "mailto:\(email)") {
                        Link(destination: url) {
                            Label(email, systemImage: "envelope")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 20)

                // Voting guide button
                Button {
                    Task {
                        isUpdating = true
                        defer { isUpdating = false }

                        if votingGuide.isSaved(candidate) {
                            await votingGuide.removeCandidate(candidate)
                        } else {
                            await votingGuide.addCandidate(candidate)
                        }
                    }
                } label: {
                    HStack {
                        if isUpdating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label(
                                votingGuide.isSaved(candidate)
                                    ? "Remove from Voting Guide"
                                    : "Add to Voting Guide",
                                systemImage: votingGuide.isSaved(candidate)
                                    ? "bookmark.fill"
                                    : "bookmark"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isUpdating)

                if !votingGuide.errorMessage.isEmpty {
                    Text(votingGuide.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle("Candidate Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await votingGuide.loadSavedCandidates()
        }
    }
}
