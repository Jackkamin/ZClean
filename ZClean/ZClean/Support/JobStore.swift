import Foundation
import SwiftData

@MainActor
enum JobStore {
    static func decryptedName(for contact: Contact?) -> String {
        guard let contact else { return "Unknown client" }
        do {
            return try NameCryptoService.shared.decrypt(contact.encryptedName)
        } catch {
            return "Encrypted name"
        }
    }

    static func fetchOrCreateContact(
        named rawName: String,
        context: ModelContext
    ) throws -> Contact {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<Contact>()
        let contacts = try context.fetch(descriptor)

        for contact in contacts {
            guard let decoded = try? NameCryptoService.shared.decrypt(contact.encryptedName) else { continue }
            if decoded.caseInsensitiveCompare(trimmed) == .orderedSame {
                return contact
            }
        }

        let encrypted = try NameCryptoService.shared.encrypt(trimmed)
        let contact = Contact(encryptedName: encrypted)
        context.insert(contact)
        return contact
    }

    static func thisMonthEarnings(from jobs: [Job]) -> Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: .now)
        let currentYear = calendar.component(.year, from: .now)

        return jobs.reduce(0) { partial, job in
            guard job.status == .completed else { return partial }
            guard let completed = job.completedAt else { return partial }
            let month = calendar.component(.month, from: completed)
            let year = calendar.component(.year, from: completed)
            guard month == currentMonth && year == currentYear else { return partial }
            return partial + (job.cashAmount ?? 0)
        }
    }

    static func upcomingJobs(_ jobs: [Job]) -> [Job] {
        let now = Date()
        return jobs
            .filter { job in
                guard job.status == .upcoming else { return false }
                guard job.isWeekly else { return true }

                let showFrom = Calendar.current.date(
                    byAdding: .hour,
                    value: -24,
                    to: scheduledAt(for: job)
                ) ?? .distantPast
                return now >= showFrom
            }
            .sorted { lhs, rhs in
                let lhsScheduledAt = scheduledAt(for: lhs)
                let rhsScheduledAt = scheduledAt(for: rhs)
                let lhsDistance = abs(lhsScheduledAt.timeIntervalSince(now))
                let rhsDistance = abs(rhsScheduledAt.timeIntervalSince(now))

                if lhsDistance == rhsDistance {
                    return lhsScheduledAt < rhsScheduledAt
                }
                return lhsDistance < rhsDistance
            }
    }

    static func completedJobs(_ jobs: [Job]) -> [Job] {
        jobs
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private static func scheduledAt(for job: Job) -> Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: job.scheduledDate)
        if let time = job.scheduledTime {
            let comps = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: comps.hour ?? 9,
                minute: comps.minute ?? 0,
                second: 0,
                of: day
            ) ?? day
        }
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
    }
}
