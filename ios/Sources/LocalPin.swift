import Foundation
import CryptoKit

enum LocalPin {
    static func make(pin: String) -> (salt: String, hash: String) {
        let salt = UUID().uuidString
        return (salt, hash(pin: pin, salt: salt))
    }

    static func verify(pin: String, salt: String, expected: String) -> Bool {
        hash(pin: pin, salt: salt) == expected
    }

    private static func hash(pin: String, salt: String) -> String {
        let data = Data("\(salt):\(pin)".utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
