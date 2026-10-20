
import SwiftUI

struct CandidateListView: View {
    @StateObject private var viewModel = CandidateViewModel()

    var body: some View {
        List(viewModel.candidates) { candidate in
            NavigationLink {
                CandidateDetailView(candidate: candidate)
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(.blue)
                        .frame(width: 55, height: 55)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(candidate.name)
                            .font(.headline)

                        Text(viewModel.positionName(for: candidate))
                            .font(.subheadline)

                        Text(viewModel.municipalityName(for: candidate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("Candidates")
        .onAppear {
            viewModel.loadCandidates()
        }
    }
}

#Preview {
    NavigationStack {
        CandidateListView()
    }
}
