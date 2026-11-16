
import SwiftUI

struct CandidateSelectionsView: View {
    @EnvironmentObject var selectionsViewModel: CandidateSelectionsViewModel
    @ObservedObject var municipalityManager = MunicipalityManager.shared

    @State private var selectionToEdit: CandidateSelection?
    @State private var selectionToDelete: CandidateSelection?
    @State private var showingDeleteConfirmation = false
    @State private var editingNotesDraft = ""

    private var activeMunicipalityName: String? {
        municipalityManager.selectedMunicipality?.name
    }

    private var displayedSelections: [CandidateSelection] {
        selectionsViewModel.filteredSelections(for: activeMunicipalityName)
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
                    withAnimation {
                        _ = selectionsViewModel.deleteSelection(selectionId: selection.id)
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
                    _ = selectionsViewModel.updateSelection(
                        selectionId: selection.id,
                        notes: newNotes
                    )
                }
            }
            .task {
                await selectionsViewModel.loadSelections()
            }
        }
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
