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
                        Button("Change City", systemImage: "arrow.triangle.2.circlepath") {
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
