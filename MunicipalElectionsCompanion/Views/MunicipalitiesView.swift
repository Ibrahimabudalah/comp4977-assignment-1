
import SwiftUI

struct MunicipalitiesView: View {
    @StateObject private var viewModel = MunicipalityViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.municipalities) { municipality in
                HStack(spacing: 15) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 35))
                        .foregroundStyle(.blue)
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(municipality.name)
                            .font(.headline)

                        Text(municipality.province)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(
                            municipality.electionDate,
                            style: .date
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Municipalities")
            .task {
                await viewModel.loadMunicipalities()
            }
        }
    }
}

#Preview {
    MunicipalitiesView()
}
