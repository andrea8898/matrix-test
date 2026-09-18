import Foundation
import UIKit

actor MatrixAPI {
    static let shared = MatrixAPI()
    private let decoder: JSONDecoder = { let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; d.dateDecodingStrategy = .iso8601; return d }()

    private func call<Input: Encodable, Output: Decodable>(_ name: String, input: Input, token: String? = nil) async throws -> Output {
        guard MatrixTestConfig.isConfigured else { throw MatrixAPIError.configuration }
        let url = MatrixTestConfig.supabaseURL.appending(path: "functions/v1/\(name)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(MatrixTestConfig.supabasePublishableKey, forHTTPHeaderField: "apikey")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(input)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MatrixAPIError.server("Risposta di rete non valida.") }
        if !(200..<300).contains(http.statusCode) {
            let remote = try? decoder.decode(ServerError.self, from: data)
            throw MatrixAPIError.server(remote?.error ?? "Errore server \(http.statusCode).")
        }
        do { return try decoder.decode(Output.self, from: data) }
        catch { throw MatrixAPIError.decoding }
    }

    private var deviceLabel: String { "iPhone \(UIDevice.current.systemVersion)" }

    func register(displayName: String, username: String, password: String) async throws -> SessionPayload {
        let publicKey = try KeychainVault.agreementKey().publicKey.rawRepresentation.base64EncodedString()
        return try await call("register", input: RegisterInput(displayName: displayName, username: username, password: password, publicKey: publicKey, deviceLabel: deviceLabel))
    }

    func bootstrapFounder(code: String, password: String) async throws -> SessionPayload {
        let publicKey = try KeychainVault.agreementKey().publicKey.rawRepresentation.base64EncodedString()
        return try await call("bootstrap-founder", input: BootstrapInput(bootstrapCode: code, password: password, publicKey: publicKey, deviceLabel: deviceLabel))
    }

    func login(username: String, password: String) async throws -> SessionPayload {
        try await call("login", input: LoginInput(username: username, password: password, deviceLabel: deviceLabel))
    }

    func find(code: String, token: String) async throws -> MatrixProfile? {
        let output: FindOutput = try await call("directory-find", input: FindInput(publicCode: code), token: token)
        return output.profile
    }

    func requestFriend(code: String, token: String) async throws {
        let _: Ok = try await call("friend-request", input: FriendInput(recipientCode: code), token: token)
    }

    func heartbeat(token: String) async throws { let _: Ok = try await call("presence-heartbeat", input: Empty(), token: token) }
    func dashboard(token: String) async throws -> DashboardOutput { try await call("admin-dashboard", input: Empty(), token: token) }
    func adminAction(code: String, action: String, token: String) async throws { let _: Ok = try await call("admin-account-action", input: AdminActionInput(publicCode: code, action: action), token: token) }
}

private struct RegisterInput: Encodable { let displayName, username, password, publicKey, deviceLabel: String }
private struct BootstrapInput: Encodable { let bootstrapCode, password, publicKey, deviceLabel: String }
private struct LoginInput: Encodable { let username, password, deviceLabel: String }
private struct FindInput: Encodable { let publicCode: String }
private struct FriendInput: Encodable { let recipientCode: String }
private struct AdminActionInput: Encodable { let publicCode, action: String }
private struct Empty: Encodable {}
private struct ServerError: Decodable { let error: String }
private struct FindOutput: Decodable { let profile: MatrixProfile? }
private struct Ok: Decodable { let ok: Bool }
