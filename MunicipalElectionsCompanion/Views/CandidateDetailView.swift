//
//  CandidateDetailView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct CandidateDetailView: View {
    let candidate: Candidate
    var availablePositions: [Position] = []

    @EnvironmentObject var selectionsViewModel: CandidateSelectionsViewModel
    @State private var showingNotesSheet = false
    @State private var notesDraft = ""
    @State private var showingDeleteAlert = false
    @State private var quotaErrorMessage: String? = nil
    @State private var showingQuotaAlert = false

    private var positionName: String {
        candidate.positionName ?? "Unknown Position"
    }

    private var municipalityName: String {
        candidate.municipalityName ?? "Unknown Municipality"
    }

    private var isSaved: Bool {
        selectionsViewModel.isCandidateSelected(candidate.candidateId)
    }

    private var currentSelection: CandidateSelection? {
        selectionsViewModel.selection(for: candidate.candidateId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Candidate Remote Photo with Fallback
                RemoteImageView(
                    urlString: candidate.photoUrl,
                    initialsText: candidate.name,
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

                    if isSaved {
                        Label("Saved to My Selections", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .bold()
                            .padding(.top, 2)
                    }
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

                // Current Saved Notes (if any)
                if let selection = currentSelection, !selection.notes.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("My Notes")
                                .font(.headline)
                            Spacer()
                            Button("Edit") {
                                notesDraft = selection.notes
                                showingNotesSheet = true
                            }
                            .font(.caption)
                        }

                        Text(selection.notes)
                            .font(.subheadline)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 20)

                // Action Buttons: Add, Edit, Delete
                VStack(spacing: 12) {
                    if isSaved {
                        // Edit Selection Button
                        Button {
                            notesDraft = currentSelection?.notes ?? ""
                            showingNotesSheet = true
                        } label: {
                            Label("Edit Selection Notes", systemImage: "pencil")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)

                        // Delete Selection Button
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Selection", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        // Add Selection Button
                        Button {
                            let validation = selectionsViewModel.validateCanSelect(
                                candidate,
                                availablePositions: availablePositions
                            )

                            if !validation.canAdd {
                                quotaErrorMessage = validation.message
                                showingQuotaAlert = true
                            } else {
                                notesDraft = ""
                                showingNotesSheet = true
                            }
                        } label: {
                            Label("Add Selection", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Candidate Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cannot Add Candidate", isPresented: $showingQuotaAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(quotaErrorMessage ?? "You have reached the maximum allowed candidates for this position.")
        }
        .confirmationDialog(
            "Delete Selection",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Remove \(candidate.name)", role: .destructive) {
                if let selection = currentSelection {
                    withAnimation {
                        _ = selectionsViewModel.deleteSelection(selectionId: selection.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(candidate.name) from your candidate selections?")
        }
        .sheet(isPresented: $showingNotesSheet) {
            EditSelectionNotesSheet(
                candidateName: candidate.name,
                positionName: positionName,
                photoUrl: candidate.photoUrl,
                notes: $notesDraft
            ) { newNotes in
                if isSaved {
                    if let selection = currentSelection {
                        _ = selectionsViewModel.updateSelection(
                            selectionId: selection.id,
                            notes: newNotes
                        )
                    }
                } else {
                    _ = selectionsViewModel.createSelection(
                        candidate: candidate,
                        notes: newNotes,
                        availablePositions: availablePositions
                    )
                }
            }
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
        .environmentObject(CandidateSelectionsViewModel())
    }
}
