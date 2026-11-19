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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var showingNotesSheet = false
    @State private var notesDraft = ""
    @State private var showingDeleteAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    // Determines current screen space
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }

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
            Group {
                if isWideLayout {
                    // iPad and iPhone Landscape
                    HStack(alignment: .top, spacing: 28) {
                        photoAndActionCard
                            .frame(width: 320)

                        detailContentSections
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // iPhone Portrait
                    VStack(spacing: 20) {
                        photoAndActionCard
                        detailContentSections
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Candidate Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            "Delete Selection",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Remove \(candidate.name)", role: .destructive) {
                if let selection = currentSelection {
                    Task {
                        report(
                            await selectionsViewModel.deleteSelection(selectionId: selection.id),
                            failureTitle: "Couldn't Remove Selection"
                        )
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
                Task {
                    if isSaved {
                        if let selection = currentSelection {
                            report(
                                await selectionsViewModel.updateSelection(selectionId: selection.id, notes: newNotes),
                                failureTitle: "Couldn't Save Notes"
                            )
                        }
                    } else {
                        report(
                            await selectionsViewModel.createSelection(
                                candidate: candidate,
                                notes: newNotes,
                                availablePositions: availablePositions
                            ),
                            failureTitle: "Couldn't Add Candidate"
                        )
                    }
                }
            }
        }
    }

    /// Shows the outcome of a write: a failure, or the "saved offline, will sync" notice.
    private func report(_ result: CandidateSelectionsViewModel.ActionResult, failureTitle: String) {
        guard let message = result.message else { return }
        alertTitle = result.success ? "Saved Offline" : failureTitle
        alertMessage = message
        showingAlert = true
    }


    private var photoAndActionCard: some View {
        VStack(spacing: 16) {
            // Candidate Remote Photo with Initials Fallback
            RemoteImageView(
                urlString: candidate.photoUrl,
                initialsText: candidate.name,
                fallbackSystemName: "person.crop.circle.fill",
                size: isWideLayout ? 130 : 120,
                shape: .circle,
                fallbackColor: .blue
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.top, 4)

            // Candidate Name & Office
            VStack(spacing: 6) {
                Text(candidate.name)
                    .font(.title2)
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

            // Action Buttons
            VStack(spacing: 10) {
                if isSaved {
                    Button {
                        notesDraft = currentSelection?.notes ?? ""
                        showingNotesSheet = true
                    } label: {
                        Label("Edit Selection Notes", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Selection", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        let validation = selectionsViewModel.validateCanSelect(
                            candidate,
                            availablePositions: availablePositions
                        )

                        if !validation.canAdd {
                            alertTitle = "Cannot Add Candidate"
                            alertMessage = validation.message
                                ?? "You have reached the maximum allowed candidates for this position."
                            showingAlert = true
                        } else {
                            notesDraft = ""
                            showingNotesSheet = true
                        }
                    } label: {
                        Label("Add Selection", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var detailContentSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Biography Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Biography")
                    .font(.headline)

                Text(candidate.biography ?? "No biography available.")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Contact Info Section
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
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Current Saved Notes
            if let selection = currentSelection, !selection.notes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("My Personal Notes")
                            .font(.headline)
                        Spacer()
                        Button("Edit") {
                            notesDraft = selection.notes
                            showingNotesSheet = true
                        }
                        .font(.caption)
                        .bold()
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "note.text")
                            .foregroundStyle(.blue)
                        Text(selection.notes)
                            .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
