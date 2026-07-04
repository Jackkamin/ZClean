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
    // CSV of weekday numbers (1...7) for weekly recurrence.
    var recurrenceWeekdaysRaw: String = ""
    // Optional free-text notes shown with the job.
    var jobDescription: String = ""
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
        recurrenceWeekdays: [Int] = [],
        jobDescription: String = "",
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
        self.recurrenceWeekdaysRaw = Job.serializeWeekdays(recurrenceWeekdays)
        self.jobDescription = jobDescription
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

    var recurrenceWeekdays: [Int] {
        get {
            recurrenceWeekdaysRaw
                .split(separator: ",")
                .compactMap { Int($0) }
                .filter { (1...7).contains($0) }
                .sorted()
        }
        set {
            recurrenceWeekdaysRaw = Job.serializeWeekdays(newValue)
        }
    }

    private static func serializeWeekdays(_ weekdays: [Int]) -> String {
        weekdays
            .filter { (1...7).contains($0) }
            .removingDuplicates()
            .sorted()
            .map(String.init)
            .joined(separator: ",")
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
