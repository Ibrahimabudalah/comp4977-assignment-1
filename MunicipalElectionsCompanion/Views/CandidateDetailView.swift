
import SwiftUI

struct CandidateDetailView: View {
    let candidate: Candidate

    private var positionName: String {
        MockData.positions.first {
            $0.positionId == candidate.positionId
        }?.name ?? "Unknown Position"
    }

    private var municipalityName: String {
        MockData.municipalities.first {
            $0.municipalityId == candidate.municipalityId
        }?.name ?? "Unknown Municipality"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                //candidate photo
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)

                //candidate name and position
                VStack(spacing: 5) {
                    Text(candidate.name)
                        .font(.title)
                        .bold()

                    Text("\(positionName) - \(municipalityName)")
                        .foregroundStyle(.secondary)
                }

                Divider()

                //biography
                VStack(alignment: .leading, spacing: 10) {
                    Text("Biography")
                        .font(.headline)

                    Text(candidate.biography ?? "No biography available.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                //contact information
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

                //voting Guide button
                Button {
                    //saving functionality will be added later
                } label: {
                    Label("Add to Voting Guide",
                          systemImage: "bookmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(true)
            }
            .padding()
        }
        .navigationTitle("Candidate Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CandidateDetailView(candidate: MockData.candidates[0])
    }
}
