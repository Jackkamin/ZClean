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
    // Legacy prefix support for records written during fallback period.
    private let fallbackPrefix = "plain:"

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
        do {
            let key = try fetchOrCreateKey()
            let box = try AES.GCM.SealedBox(combined: encryptedName)
            let decrypted = try AES.GCM.open(box, using: key)
            guard let plainText = String(data: decrypted, encoding: .utf8) else {
                throw NameCryptoError.utf8DecodeFailed
            }
            return plainText
        } catch {
            guard let fallback = String(data: encryptedName, encoding: .utf8),
                  fallback.hasPrefix(fallbackPrefix) else {
                throw error
            }
            return String(fallback.dropFirst(fallbackPrefix.count))
        }
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
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrService as String: keyTag
        ]

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrService as String: keyTag,
            kSecValueData as String: data,
            // Must not be ThisDeviceOnly: the key has to migrate with encrypted
            // backups, or restored databases become undecryptable.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let update: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let updateStatus = SecItemUpdate(identity as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(updateStatus))
            }
            return
        }

        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
