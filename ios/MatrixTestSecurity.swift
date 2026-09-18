import Foundation
import Security

/// Stores only an opaque device key reference. Conversation plaintext must not be persisted.
enum MatrixTestSecurity {
    static let service = "com.matrix.test"
    static let account = "device-key-reference"

    static func eraseDeviceSecrets() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        let result = SecItemDelete(query as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(result))
        }
    }
}
