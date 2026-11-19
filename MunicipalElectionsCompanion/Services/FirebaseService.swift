//
//  FirebaseService.swift
//  MunicipalElectionsCompanion
//
//  The only file that talks to Firebase Auth and Firestore. ViewModels call it; Views never do.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// The result of one Firestore read of a user's selections, already decoded and sorted newest first.
struct SelectionsSnapshot {
    let selections: [CandidateSelection]
    /// Documents that exist but could not be decoded into a `CandidateSelection`.
    let skippedCount: Int
    /// True when served from the local cache, i.e. not yet confirmed by the server.
    let isFromCache: Bool
}

enum FirebaseServiceError: LocalizedError {
    /// A Firebase account already exists for this email but with a different password than the API login.
    case accountMismatch
    /// The server did not confirm a write in time; Firestore keeps it queued and syncs it later.
    case writeTimedOut
    /// Firestore returned neither data nor an error.
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .accountMismatch:
            return "Your cloud storage account uses a different password than your login, so it can't be opened. Please contact support."
        case .writeTimedOut:
            return "Can't reach cloud storage. Your change is saved on this device and will sync when you're back online."
        case .invalidResponse:
            return "Cloud storage sent an unexpected response. Please try again."
        }
    }
}

@MainActor
final class FirebaseService {
    static let shared = FirebaseService()

    /// How long a write waits for the server before reporting `.writeTimedOut`.
    private let writeTimeout: TimeInterval = 8

    // lazy so nothing touches Firebase until first use (SwiftUI previews never run FirebaseApp.configure())
    private lazy var db = Firestore.firestore()
    private let selectionsCollection = "CandidateSelections"
    private let profilesCollection = "UserProfiles"

    private init() {}

    // MARK: - Authentication

    /// Mirrors the API login into Firebase Auth with the same email and password (Firestore rules need
    /// `request.auth`). Creates the Firebase account on the user's first login.
    func signIn(email: String, password: String) async throws {
        let email = Self.normalize(email)

        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            // With email-enumeration protection on, "no such user" and "wrong password" both arrive
            // as .invalidCredential, so try to create the account and let that call tell them apart.
            let code = Self.authCode(error)
            guard code == .userNotFound || code == .invalidCredential else { throw error }

            do {
                _ = try await Auth.auth().createUser(withEmail: email, password: password)
            } catch {
                if Self.authCode(error) == .emailAlreadyInUse { throw FirebaseServiceError.accountMismatch }
                throw error
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - Candidate selections

    /// Live updates for one user's selections in one municipality. Returns a function that stops the
    /// listener (so callers never need to import Firestore). `onChange` runs on the main actor
    /// (Firestore delivers callbacks on the main queue).
    func listenToSelections(
        email: String,
        municipalityId: Int,
        onChange: @escaping @MainActor (Result<SelectionsSnapshot, Error>) -> Void
    ) -> () -> Void {
        let registration = selectionsQuery(email: email, municipalityId: municipalityId).addSnapshotListener { snapshot, error in
            MainActor.assumeIsolated {
                if let snapshot {
                    onChange(.success(Self.decode(snapshot)))
                } else {
                    onChange(.failure(error ?? FirebaseServiceError.invalidResponse))
                }
            }
        }
        return { registration.remove() }
    }

    /// One-shot read straight from the server (pull to refresh). Throws when offline.
    func fetchSelections(email: String, municipalityId: Int) async throws -> SelectionsSnapshot {
        let snapshot = try await selectionsQuery(email: email, municipalityId: municipalityId)
            .getDocuments(source: .server)
        return Self.decode(snapshot)
    }

    /// Creates or overwrites the document `selection.id` (use `selectionId(email:candidateId:)`).
    func saveSelection(_ selection: CandidateSelection) async throws {
        let data = try Firestore.Encoder().encode(selection)
        let ref = db.collection(selectionsCollection).document(selection.id)
        try await commit { ref.setData(data, completion: $0) }
    }

    func deleteSelection(id: String) async throws {
        let ref = db.collection(selectionsCollection).document(id)
        try await commit { ref.delete(completion: $0) }
    }

    // MARK: - User profile (selected municipality)

    /// Returns nil when the user has no saved profile yet (first login).
    func getProfile(email: String) async throws -> UserProfile? {
        let document = try await db.collection(profilesCollection)
            .document(Self.normalize(email))
            .getDocument()
        guard document.exists else { return nil }
        return try document.data(as: UserProfile.self)
    }

    func saveProfile(email: String, municipalityId: Int, municipalityName: String) async throws {
        let email = Self.normalize(email)
        let profile = UserProfile(
            userEmail: email,
            municipalityId: municipalityId,
            municipalityName: municipalityName,
            dateModified: Date()
        )
        let data = try Firestore.Encoder().encode(profile)
        let ref = db.collection(profilesCollection).document(email)
        try await commit { ref.setData(data, completion: $0) }
    }

    // MARK: - Helpers

    /// Firebase Auth stores emails lowercased, and the security rules compare against that.
    nonisolated static func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// One document per user per candidate: the id itself makes a duplicate save impossible.
    nonisolated static func selectionId(email: String, candidateId: Int) -> String {
        "\(normalize(email))_\(candidateId)"
    }

    nonisolated static let offlineMessage = "Can't reach cloud storage. Check your connection; changes will sync when you're back online."
    nonisolated static let permissionMessage = "You don't have permission to access this data. Please log in again."
    nonisolated static let unreadableSelectionsMessage = "Some saved selections could not be read."
    nonisolated static let genericMessage = "Something went wrong saving your selection. Please try again."

    /// Turns any error from this service into text that is safe to show to the user.
    nonisolated static func message(for error: Error) -> String {
        if let error = error as? FirebaseServiceError {
            return error.errorDescription ?? genericMessage
        }
        if error is DecodingError {
            return "Some saved data could not be read."
        }
        if let code = firestoreCode(error) {
            switch code {
            case .unavailable, .deadlineExceeded: return offlineMessage
            case .permissionDenied, .unauthenticated: return permissionMessage
            default: break
            }
        }
        if let code = authCode(error) {
            switch code {
            case .networkError: return offlineMessage
            case .tooManyRequests: return "Too many attempts. Please wait a moment and try again."
            default: break
            }
        }
        return genericMessage
    }

    private nonisolated static func authCode(_ error: Error) -> AuthErrorCode? {
        let nsError = error as NSError
        return nsError.domain == AuthErrorDomain ? AuthErrorCode(rawValue: nsError.code) : nil
    }

    private nonisolated static func firestoreCode(_ error: Error) -> FirestoreErrorCode.Code? {
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain ? FirestoreErrorCode.Code(rawValue: nsError.code) : nil
    }

    // Equality filters only, so no composite index is needed; sorting happens in `decode`.
    private func selectionsQuery(email: String, municipalityId: Int) -> Query {
        db.collection(selectionsCollection)
            .whereField("userEmail", isEqualTo: Self.normalize(email))
            .whereField("municipalityId", isEqualTo: municipalityId)
    }

    private static func decode(_ snapshot: QuerySnapshot) -> SelectionsSnapshot {
        var selections: [CandidateSelection] = []
        var skipped = 0
        for document in snapshot.documents {
            do {
                selections.append(try document.data(as: CandidateSelection.self))
            } catch {
                skipped += 1
            }
        }
        selections.sort { $0.dateCreated > $1.dateCreated }
        return SelectionsSnapshot(
            selections: selections,
            skippedCount: skipped,
            isFromCache: snapshot.metadata.isFromCache
        )
    }

    /// Waits for the server to confirm a write, but not forever. Offline, Firestore queues the write and
    /// only calls back after it reconnects, which would leave the UI waiting indefinitely. After
    /// `writeTimeout` this throws `.writeTimedOut`; the write itself stays queued and syncs later.
    private func commit(_ write: (@escaping @Sendable (Error?) -> Void) -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let gate = ResumeOnce(continuation)
            write { gate.finish($0) }
            DispatchQueue.main.asyncAfter(deadline: .now() + writeTimeout) {
                gate.finish(FirebaseServiceError.writeTimedOut)
            }
        }
    }
}

/// Resumes a continuation exactly once, whichever of the write callback and the timeout fires first.
/// `@unchecked Sendable` is safe here: Firestore calls back on the main queue and so does the timer,
/// so `finish` never runs concurrently with itself.
private nonisolated final class ResumeOnce: @unchecked Sendable {
    private var continuation: CheckedContinuation<Void, Error>?

    init(_ continuation: CheckedContinuation<Void, Error>) {
        self.continuation = continuation
    }

    func finish(_ error: Error?) {
        guard let continuation else { return }
        self.continuation = nil
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
}
