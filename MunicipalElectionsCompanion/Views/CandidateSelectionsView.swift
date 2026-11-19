
import SwiftUI

struct CandidateSelectionsView: View {
    @EnvironmentObject var selectionsViewModel: CandidateSelectionsViewModel
    @ObservedObject var municipalityManager = MunicipalityManager.shared

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var selectionToEdit: CandidateSelection?
    @State private var selectionToDelete: CandidateSelection?
    @State private var showingDeleteConfirmation = false
    @State private var editingNotesDraft = ""
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    private var activeMunicipalityName: String? {
        municipalityManager.selectedMunicipality?.name
    }

    private var displayedSelections: [CandidateSelection] {
        selectionsViewModel.selections
    }

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var isPhoneLandscape: Bool {
        UIDevice.current.userInterfaceIdiom == .phone && verticalSizeClass == .compact
    }

    private var isGridMode: Bool {
        isIPad || isPhoneLandscape
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayedSelections.isEmpty {
                    ContentUnavailableView(
                        "No Candidate Selections",
                        systemImage: "checklist.checked",
                        description: Text(
                            activeMunicipalityName != nil
                                ? "You haven't saved any candidates for \(activeMunicipalityName!). Browse the directory to build your guide."
                                : "You haven't saved any candidates yet."
                        )
                    )
                } else if isGridMode {
                    // Adaptive Grid Layout for iPad and iPhone Landscape
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let municipality = municipalityManager.selectedMunicipality {
                                HStack {
                                    Text("Saved Candidates (\(displayedSelections.count))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("City: \(municipality.name)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                            }

                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: isPhoneLandscape ? 300 : 340), spacing: 16)
                                ],
                                spacing: 16
                            ) {
                                ForEach(displayedSelections) { selection in
                                    selectionCard(for: selection)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    List {
                        Section {
                            ForEach(displayedSelections) { selection in
                                selectionRow(for: selection)
                            }
                        } header: {
                            HStack {
                                Text("Saved Candidates (\(displayedSelections.count))")
                                Spacer()
                                if let municipality = municipalityManager.selectedMunicipality {
                                    Text("City: \(municipality.name)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Selections")
            .safeAreaInset(edge: .top) {
                if let message = selectionsViewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(.bar)
                }
            }
            .refreshable {
                await selectionsViewModel.loadSelections()
            }
            .confirmationDialog(
                "Remove Candidate",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: selectionToDelete
            ) { selection in
                Button("Remove \(selection.candidateName)", role: .destructive) {
                    Task {
                        report(
                            await selectionsViewModel.deleteSelection(selectionId: selection.id),
                            failureTitle: "Couldn't Remove Selection"
                        )
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { selection in
                Text("Are you sure you want to remove \(selection.candidateName) from your candidate selections?")
            }
            .sheet(item: $selectionToEdit) { selection in
                EditSelectionNotesSheet(
                    candidateName: selection.candidateName,
                    positionName: selection.positionName,
                    photoUrl: selection.photoUrl,
                    notes: $editingNotesDraft
                ) { newNotes in
                    Task {
                        report(
                            await selectionsViewModel.updateSelection(selectionId: selection.id, notes: newNotes),
                            failureTitle: "Couldn't Save Notes"
                        )
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
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

    // Adaptive card for iPad & iPhone Landscape
    @ViewBuilder
    private func selectionCard(for selection: CandidateSelection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RemoteImageView(
                    urlString: selection.photoUrl,
                    initialsText: selection.candidateName,
                    fallbackSystemName: "person.crop.circle.fill",
                    size: 52,
                    shape: .circle,
                    fallbackColor: .blue
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(selection.candidateName)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(selection.positionName) • \(selection.municipalityName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("Saved: \(selection.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button {
                        editingNotesDraft = selection.notes
                        selectionToEdit = selection
                    } label: {
                        Label("Edit Notes", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        selectionToDelete = selection
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Remove Selection", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
            }

            if !selection.notes.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 2)

                    Text(selection.notes)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func selectionRow(for selection: CandidateSelection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                // Candidate Photo
                RemoteImageView(
                    urlString: selection.photoUrl,
                    initialsText: selection.candidateName,
                    fallbackSystemName: "person.crop.circle.fill",
                    size: 52,
                    shape: .circle,
                    fallbackColor: .blue
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(selection.candidateName)
                        .font(.headline)

                    Text("\(selection.positionName) • \(selection.municipalityName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Saved: \(selection.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Actions Menu
                Menu {
                    Button {
                        editingNotesDraft = selection.notes
                        selectionToEdit = selection
                    } label: {
                        Label("Edit Notes", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        selectionToDelete = selection
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Remove Selection", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
            }

            // User Notes Box
            if !selection.notes.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 2)

                    Text(selection.notes)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                selectionToDelete = selection
                showingDeleteConfirmation = true
            } label: {
                Label("Remove", systemImage: "trash")
            }

            Button {
                editingNotesDraft = selection.notes
                selectionToEdit = selection
            } label: {
                Label("Edit Notes", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

#Preview {
    NavigationStack {
        CandidateSelectionsView()
            .environmentObject(CandidateSelectionsViewModel())
    }
}
