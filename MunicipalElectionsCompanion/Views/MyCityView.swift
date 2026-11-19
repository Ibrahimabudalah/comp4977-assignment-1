//
//  MyCityView.swift
//  MunicipalElectionsCompanion
//
//  Home screen: shows only the municipality the user selected (spec Part 3).
//

import SwiftUI

struct MyCityView: View {
    @ObservedObject var municipalityManager = MunicipalityManager.shared
    @State private var showingMunicipalityPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if let municipality = municipalityManager.selectedMunicipality {
                    MunicipalityDetailView(municipality: municipality)
                } else if municipalityManager.isLoading {
                    ProgressView("Loading your city...")
                } else if !municipalityManager.errorMessage.isEmpty {
                    // The user may have chosen a city already; the list just failed to load, so offer a retry
                    ContentUnavailableView {
                        Label("Couldn't Load Your City", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(municipalityManager.errorMessage + " Check your connection and try again.")
                    } actions: {
                        Button("Try Again") {
                            Task { await municipalityManager.restore() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView {
                        Label("No City Selected", systemImage: "building.2")
                    } description: {
                        Text("Choose the municipality where you live to see its election information.")
                    } actions: {
                        Button("Select Municipality") {
                            showingMunicipalityPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .toolbar {
                if municipalityManager.selectedMunicipality != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Change City", systemImage: "building.2") {
                            showingMunicipalityPicker = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingMunicipalityPicker) {
                MunicipalitySelectionView(isMandatory: false)
            }
        }
    }
}

#Preview {
    MyCityView()
}
