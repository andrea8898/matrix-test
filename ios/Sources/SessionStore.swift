import Foundation

@MainActor
final class SessionStore: ObservableObject {
    enum State { case welcome, bootstrap, register, login, locked, home }
    @Published var state: State = .welcome
    @Published private(set) var session: StoredSession?
    @Published var errorMessage: String?

    init() { session = try? KeychainVault.session(); if session != nil { state = .locked } }

    func register(displayName: String, username: String, password: String, localPin: String) async {
        await perform(username: username, displayName: displayName, isFounder: false, localPin: localPin) { try await MatrixAPI.shared.register(displayName: displayName, username: username, password: password) }
    }

    func bootstrapFounder(code: String, password: String, localPin: String) async {
        await perform(username: "Black", displayName: "Ghost", isFounder: true, localPin: localPin) { try await MatrixAPI.shared.bootstrapFounder(code: code, password: password) }
    }

    func login(username: String, password: String, localPin: String) async {
        await perform(username: username, displayName: username, isFounder: username.caseInsensitiveCompare("Black") == .orderedSame, localPin: localPin) { try await MatrixAPI.shared.login(username: username, password: password) }
    }

    private func perform(username: String, displayName: String, isFounder: Bool, localPin: String, _ call: () async throws -> SessionPayload) async {
        errorMessage = nil
        guard localPin.range(of: "^[0-9]{4,6}$", options: .regularExpression) != nil else { errorMessage = "Il codice locale deve avere 4–6 cifre."; return }
        do {
            let payload = try await call()
            let pin = LocalPin.make(pin: localPin)
            let stored = StoredSession(profileId: payload.profileId, publicCode: payload.publicCode, username: username, displayName: payload.displayName ?? displayName, token: payload.sessionToken, isFounder: payload.isFounder ?? isFounder, localPinSalt: pin.salt, localPinHash: pin.hash)
            try KeychainVault.save(session: stored)
            session = stored
            state = .home
        } catch { errorMessage = error.localizedDescription }
    }

    func resetLocalDevice() {
        try? KeychainVault.eraseAll()
        session = nil
        errorMessage = nil
        state = .welcome
    }

    func unlock(localPin: String) {
        guard let session else { state = .welcome; return }
        // One incorrect code removes local credentials and device keys immediately.
        guard LocalPin.verify(pin: localPin, salt: session.localPinSalt, expected: session.localPinHash) else { resetLocalDevice(); return }
        state = .home
    }
}
