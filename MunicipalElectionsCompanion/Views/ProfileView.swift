//
//  ProfileView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var votingGuide: VotingGuideViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()

                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue)

                            Text(viewModel.loggedInName)
                                .font(.title2)
                                .bold()

                            Text(viewModel.loggedInEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 20)

                        Spacer()
                    }
                }

                Section("Account Information") {
                    LabeledContent(
                        "Name",
                        value: viewModel.loggedInName
                    )

                    LabeledContent(
                        "Email",
                        value: viewModel.loggedInEmail
                    )
                }

                Section {
                    Button(role: .destructive) {
                        votingGuide.clearVotingGuide()
                        viewModel.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
