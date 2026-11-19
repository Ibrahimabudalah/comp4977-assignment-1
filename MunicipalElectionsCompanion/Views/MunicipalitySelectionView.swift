
import SwiftUI

struct MunicipalitySelectionView: View {
    @ObservedObject var municipalityManager = MunicipalityManager.shared
    var isMandatory: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var selectedId: Int?
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Banner
                VStack(spacing: 8) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.blue)

                    Text(isMandatory ? "Select Your Municipality" : "Change Municipality")
                        .font(.title2)
                        .bold()

                    Text("Please choose the municipality in which you reside. Candidate information and election offices will be filtered to this city.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)

                Divider()

                if municipalityManager.isLoading && municipalityManager.availableMunicipalities.isEmpty {
                    Spacer()
                    ProgressView("Loading municipalities...")
                    Spacer()
                } else if municipalityManager.availableMunicipalities.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Municipalities Found",
                        systemImage: "building.2",
                        description: Text("Could not retrieve municipality records from the server.")
                    )
                    Spacer()
                } else {
                    List(municipalityManager.availableMunicipalities) { municipality in
                        Button {
                            selectedId = municipality.municipalityId
                        } label: {
                            HStack(spacing: 14) {
                                RemoteImageView(
                                    urlString: municipality.displayLogoUrl,
                                    fallbackSystemName: "building.2.crop.circle",
                                    size: 48,
                                    shape: .roundedRectangle(cornerRadius: 10)
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(municipality.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text(municipality.province)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(municipality.electionDate, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }

                                Spacer()

                                if selectedId == municipality.municipalityId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.insetGrouped)
                }

                // Confirm Selection Button
                VStack(spacing: 10) {
                    Button {
                        guard let selectedId,
                              let chosen = municipalityManager.availableMunicipalities.first(where: { $0.municipalityId == selectedId })
                        else { return }

                        isSaving = true
                        Task {
                            do {
                                try await municipalityManager.selectMunicipality(chosen)
                                dismiss()
                            } catch {
                                // Not saved to Firebase, so the previous city stays selected
                                saveError = FirebaseService.message(for: error)
                            }
                            isSaving = false
                        }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text(isMandatory ? "Confirm & Continue" : "Save Selection")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedId == nil || isSaving)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isMandatory {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(isMandatory)
            .alert(
                "Couldn't Save Municipality",
                isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
            .task {
                if municipalityManager.availableMunicipalities.isEmpty {
                    await municipalityManager.loadAvailableMunicipalities()
                }
                if let current = municipalityManager.selectedMunicipality {
                    selectedId = current.municipalityId
                }
            }
        }
    }
}

#Preview {
    MunicipalitySelectionView(isMandatory: true)
}
