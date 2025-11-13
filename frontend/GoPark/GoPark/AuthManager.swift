import Foundation
import Firebase
import FirebaseAuth
import Combine

final class AuthManager: ObservableObject {
    @Published var userSession: User?

    static let shared = AuthManager()

    init() {
        userSession = Auth.auth().currentUser
    }

    @MainActor
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.userSession = result.user
    }

    @MainActor
    func signUp(email: String, password: String, fullName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.userSession = result.user
        let changeRequest = self.userSession?.createProfileChangeRequest()
        changeRequest?.displayName = fullName
        try await changeRequest?.commitChanges()
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
