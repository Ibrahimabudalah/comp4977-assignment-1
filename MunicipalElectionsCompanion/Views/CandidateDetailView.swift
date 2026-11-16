//
//  CandidateDetailView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

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
                // Candidate Remote Photo with Fallback
                RemoteImageView(
                    urlString: candidate.photoUrl,
                    fallbackSystemName: "person.crop.circle.fill",
                    size: 120,
                    shape: .circle,
                    fallbackColor: .blue
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.top, 10)

                // Candidate Name & Office
                VStack(spacing: 6) {
                    Text(candidate.name)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text("\(positionName) • \(municipalityName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Divider()

                // Biography
                VStack(alignment: .leading, spacing: 10) {
                    Text("Biography")
                        .font(.headline)

                    Text(candidate.biography ?? "No biography available.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Contact Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Information")
                        .font(.headline)

                    if let website = candidate.website,
                       !website.isEmpty,
                       let url = URL(string: website) {
                        Link(destination: url) {
                            Label(website, systemImage: "globe")
                                .font(.subheadline)
                        }
                    }

                    if let email = candidate.email,
                       !email.isEmpty,
                       let url = URL(string: "mailto:\(email)") {
                        Link(destination: url) {
                            Label(email, systemImage: "envelope")
                                .font(.subheadline)
                        }
                    }

                    if (candidate.website == nil || candidate.website!.isEmpty) &&
                        (candidate.email == nil || candidate.email!.isEmpty) {
                        Text("No contact information provided.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 20)

                // Voting Guide Button
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
                            .font(.headline)
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

#Preview {
    NavigationStack {
        CandidateDetailView(
            candidate: Candidate(
                candidateId: 1,
                name: "Jane Doe",
                biography: "Lifelong resident dedicated to sustainable urban development and community engagement.",
                photoUrl: "https://example.com/jane.jpg",
                website: "https://janedoe.ca",
                email: "jane@burnaby.ca",
                positionId: 1,
                municipalityId: 1,
                positionName: "Mayor",
                municipalityName: "Burnaby"
            )
        )
        .environmentObject(VotingGuideViewModel())
    }
}
