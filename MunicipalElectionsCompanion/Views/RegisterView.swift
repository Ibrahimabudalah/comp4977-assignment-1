//
//  RegisterView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-21.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 65))
                    .foregroundStyle(.blue)

                Text("Create Account")
                    .font(.largeTitle)
                    .bold()

                Text("Register to build your voting guide")
                    .foregroundStyle(.secondary)

                VStack(spacing: 15) {
                    TextField("Full Name", text: $viewModel.name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm Password",
                                text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                }

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button {
                    viewModel.register()
                } label: {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding(5)
                }
                .buttonStyle(.borderedProminent)

                Button("Already have an account? Login") {
                    dismiss()
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Registration Successful",
            isPresented: $viewModel.registrationSuccessful
        ) {
            Button("OK") {
                viewModel.password = ""
                viewModel.confirmPassword = ""
                dismiss()
            }
        } message: {
            Text("Your account has been created. Please log in.")
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(viewModel: AuthViewModel())
    }
}
