//
//  UserProfile.swift
//  MunicipalElectionsCompanion
//
//  Firestore document in the "UserProfiles" collection; the document id is the user's lowercased email.
//

import Foundation

struct UserProfile: Codable, Equatable {
    let userEmail: String
    let municipalityId: Int
    let municipalityName: String
    var dateModified: Date
}
