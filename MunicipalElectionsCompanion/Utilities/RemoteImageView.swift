//
//  RemoteImageView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-11-15.
//

import SwiftUI

enum RemoteImageShape {
    case circle
    case roundedRectangle(cornerRadius: CGFloat)
}

struct RemoteImageView: View {
    let urlString: String?
    var initialsText: String? = nil
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

    private var initials: String {
        guard let initialsText else { return "" }
        let words = initialsText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let firstWord = words.first, let char = firstWord.first {
            return String(char).uppercased()
        }
        return ""
    }

    private var avatarColor: Color {
        guard let initialsText, !initialsText.isEmpty else { return fallbackColor }
        let palette: [Color] = [.blue, .indigo, .purple, .teal, .cyan, .mint]
        let hash = abs(initialsText.hashValue)
        return palette[hash % palette.count]
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
                        .frame(width: size, height: size)
                        .clipped()
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
            if !initials.isEmpty {
                avatarColor.opacity(0.18)
                    .frame(width: size, height: size)

                Text(initials)
                    .font(.system(size: size * 0.40, weight: .bold, design: .rounded))
                    .foregroundStyle(avatarColor)
            } else {
                placeholderBackground
                Image(systemName: fallbackSystemName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(fallbackColor)
                    .padding(size * 0.18)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Initials avatar fallback
        RemoteImageView(
            urlString: nil,
            initialsText: "Jane Doe",
            size: 60,
            shape: .circle
        )

        // Initials single word
        RemoteImageView(
            urlString: nil,
            initialsText: "Mayor",
            size: 60,
            shape: .circle
        )

        // System icon fallback
        RemoteImageView(
            urlString: nil,
            fallbackSystemName: "building.2.crop.circle",
            size: 60,
            shape: .roundedRectangle(cornerRadius: 14)
        )
    }
    .padding()
}
