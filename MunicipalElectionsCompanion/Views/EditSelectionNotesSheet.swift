
import SwiftUI

struct EditSelectionNotesSheet: View {
    let candidateName: String
    let positionName: String
    let photoUrl: String?
    @Binding var notes: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftNotes: String = ""

    private let maxCharacters = 500

    private var charactersRemaining: Int {
        maxCharacters - draftNotes.count
    }

    private var isOverLimit: Bool {
        draftNotes.count > maxCharacters
    }

    var body: some View {
        NavigationStack {
            Form {
                // Candidate Summary
                Section {
                    HStack(spacing: 14) {
                        RemoteImageView(
                            urlString: photoUrl,
                            initialsText: candidateName,
                            fallbackSystemName: "person.crop.circle.fill",
                            size: 50,
                            shape: .circle,
                            fallbackColor: .blue
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(candidateName)
                                .font(.headline)

                            Text(positionName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Notes Editor
                Section {
                    TextEditor(text: $draftNotes)
                        .frame(minHeight: 140)

                    HStack {
                        Spacer()
                        Text("\(draftNotes.count) / \(maxCharacters) characters")
                            .font(.caption)
                            .foregroundStyle(isOverLimit ? .red : .secondary)
                            .bold(isOverLimit)
                    }
                } header: {
                    Text("Your Personal Notes")
                } footer: {
                    if isOverLimit {
                        Text("Notes cannot exceed 500 characters.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Add notes about this candidate's platform, policies, or why you selected them.")
                    }
                }
            }
            .navigationTitle("Selection Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draftNotes)
                        dismiss()
                    }
                    .disabled(isOverLimit)
                    .bold()
                }
            }
            .onAppear {
                draftNotes = notes
            }
        }
    }
}

#Preview {
    EditSelectionNotesSheet(
        candidateName: "Jane Doe",
        positionName: "Mayor",
        photoUrl: nil,
        notes: .constant("Great community focus on green parks."),
        onSave: { _ in }
    )
}
