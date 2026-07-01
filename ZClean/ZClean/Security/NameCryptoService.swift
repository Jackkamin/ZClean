import Foundation
import CryptoKit
import Security

enum NameCryptoError: Error {
    case missingKeyData
    case badCombinedData
    case utf8DecodeFailed
}

final class NameCryptoService {
    static let shared = NameCryptoService()
    private let keyTag = "com.cleaningjob.namekey"

    private init() {}

    func encrypt(_ plainName: String) throws -> Data {
        let key = try fetchOrCreateKey()
        let plainData = Data(plainName.utf8)
        let sealed = try AES.GCM.seal(plainData, using: key)
        guard let combined = sealed.combined else {
            throw NameCryptoError.badCombinedData
        }
        return combined
    }

    func decrypt(_ encryptedName: Data) throws -> String {
        let key = try fetchOrCreateKey()
        let box = try AES.GCM.SealedBox(combined: encryptedName)
        let decrypted = try AES.GCM.open(box, using: key)
        guard let plainText = String(data: decrypted, encoding: .utf8) else {
            throw NameCryptoError.utf8DecodeFailed
        }
        return plainText
    }

    private func fetchOrCreateKey() throws -> SymmetricKey {
        if let keyData = try fetchKeyData() {
            return SymmetricKey(data: keyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let data = newKey.withUnsafeBytes { Data($0) }
        try storeKeyData(data)
        return newKey
    }

    private func fetchKeyData() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrService as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        return item as? Data
    }

    private func storeKeyData(_ data: Data) throws {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrService as String: keyTag,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
