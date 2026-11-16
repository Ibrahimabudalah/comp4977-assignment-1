//
//  CandidateSelection.swift
//  MunicipalElectionsCompanion
//
//  Created by Ibrahim Abudalah on 2026-11-15.
//

import Foundation

struct CandidateSelection: Identifiable, Codable, Equatable {
    let id: String
    let userEmail: String
    let candidateId: Int
    let candidateName: String
    let positionName: String
    let municipalityName: String
    let photoUrl: String?
    var notes: String
    let dateCreated: Date
    var dateModified: Date

    init(
        id: String = UUID().uuidString,
        userEmail: String,
        candidateId: Int,
        candidateName: String,
        positionName: String,
        municipalityName: String,
        photoUrl: String? = nil,
        notes: String = "",
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.userEmail = userEmail
        self.candidateId = candidateId
        self.candidateName = candidateName
        self.positionName = positionName
        self.municipalityName = municipalityName
        self.photoUrl = photoUrl
        self.notes = notes
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
}
