import Foundation
import SwiftData

enum JobStatus: String, Codable, CaseIterable {
    case upcoming
    case completed
}

@Model
final class Job {
    @Attribute(.unique) var id: UUID
    var scheduledDate: Date
    var scheduledTime: Date?
    // Default value keeps older stored records compatible after schema updates.
    var durationHours: Int = 1
    var expectedAmount: Double
    var cashAmount: Double?
    var isWeekly: Bool
    var statusRaw: String
    var notificationId: String?
    var completedAt: Date?
    var createdAt: Date

    @Relationship(deleteRule: .nullify) var contact: Contact?

    init(
        id: UUID = UUID(),
        contact: Contact? = nil,
        scheduledDate: Date,
        scheduledTime: Date? = nil,
        durationHours: Int = 1,
        expectedAmount: Double,
        cashAmount: Double? = nil,
        isWeekly: Bool = false,
        status: JobStatus = .upcoming,
        notificationId: String? = nil,
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.contact = contact
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.durationHours = max(1, durationHours)
        self.expectedAmount = expectedAmount
        self.cashAmount = cashAmount
        self.isWeekly = isWeekly
        self.statusRaw = status.rawValue
        self.notificationId = notificationId
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    var status: JobStatus {
        get { JobStatus(rawValue: statusRaw) ?? .upcoming }
        set { statusRaw = newValue.rawValue }
    }
}
