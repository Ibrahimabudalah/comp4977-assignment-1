//
//  LoginView.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-10-20.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 65))
                    .foregroundStyle(.blue)

                Text("Municipal Elections")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("Sign in to create your voting guide")
                    .foregroundStyle(.secondary)

                VStack(spacing: 15) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isLoading)

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isLoading)
                }

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await viewModel.login()
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Login")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                NavigationLink {
                    RegisterView(viewModel: viewModel)
                } label: {
                    Text("Don't have an account? Register")
                }
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
}
