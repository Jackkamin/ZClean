import Foundation
import SwiftData

@Model
final class Contact {
    @Attribute(.unique) var id: UUID
    var encryptedName: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        encryptedName: Data,
        createdAt: Date = .now
    ) {
        self.id = id
        self.encryptedName = encryptedName
        self.createdAt = createdAt
    }
}
