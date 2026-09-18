import Foundation
import Security
import CryptoKit

enum KeychainVault {
    private static let service = "com.matrix.test"
    private static let sessionAccount = "matrix-session"
    private static let keyAccount = "matrix-agreement-private-key"

    static func write(_ value: Data, account: String) throws {
        try? erase(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: value
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    static func read(account: String) throws -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account, kSecReturnData as String: true]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return data
    }

    static func erase(account: String) throws {
        let status = SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    static func eraseAll() throws { try erase(account: sessionAccount); try erase(account: keyAccount) }

    static func agreementKey() throws -> Curve25519.KeyAgreement.PrivateKey {
        if let data = try read(account: keyAccount) { return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) }
        let key = Curve25519.KeyAgreement.PrivateKey()
        try write(key.rawRepresentation, account: keyAccount)
        return key
    }

    static func save(session: StoredSession) throws { try write(try JSONEncoder().encode(session), account: sessionAccount) }
    static func session() throws -> StoredSession? { guard let data = try read(account: sessionAccount) else { return nil }; return try JSONDecoder().decode(StoredSession.self, from: data) }
}

struct StoredSession: Codable {
    let profileId: UUID
    let publicCode: String
    let username: String
    let displayName: String
    let token: String
    let isFounder: Bool
    let localPinSalt: String
    let localPinHash: String
}
