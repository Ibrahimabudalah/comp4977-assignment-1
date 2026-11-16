
import SwiftUI

enum RemoteImageShape {
    case circle
    case roundedRectangle(cornerRadius: CGFloat)
}

struct RemoteImageView: View {
    let urlString: String?
    var fallbackSystemName: String = "person.crop.circle.fill"
    var size: CGFloat = 50
    var shape: RemoteImageShape = .circle
    var fallbackColor: Color = .blue

    private var imageURL: URL? {
        guard let urlString, !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(string: urlString)
    }

    var body: some View {
        Group {
            switch shape {
            case .circle:
                imageContent
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.secondary.opacity(0.15), lineWidth: 1))
            case .roundedRectangle(let radius):
                imageContent
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var imageContent: some View {
        if let url = imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        placeholderBackground
                        ProgressView()
                            .tint(fallbackColor)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackView
                @unknown default:
                    fallbackView
                }
            }
        } else {
            fallbackView
        }
    }

    private var placeholderBackground: some View {
        Color(.systemGray6)
            .frame(width: size, height: size)
    }

    private var fallbackView: some View {
        ZStack {
            placeholderBackground
            Image(systemName: fallbackSystemName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(fallbackColor)
                .padding(size * 0.18)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RemoteImageView(
            urlString: "https://ex.ca/photo.jpg",
            size: 60,
            shape: .circle
        )

        RemoteImageView(
            urlString: nil,
            fallbackSystemName: "building.2.crop.circle",
            size: 80,
            shape: .roundedRectangle(cornerRadius: 16)
        )
    }
    .padding()
}
