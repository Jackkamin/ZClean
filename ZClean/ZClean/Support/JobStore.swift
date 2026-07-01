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

        if let existing = contacts.first(where: { decryptedName(for: $0).caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
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
        jobs
            .filter { $0.status == .upcoming }
            .sorted {
                if Calendar.current.isDate($0.scheduledDate, inSameDayAs: $1.scheduledDate) {
                    return ($0.scheduledTime ?? .distantPast) < ($1.scheduledTime ?? .distantPast)
                }
                return $0.scheduledDate < $1.scheduledDate
            }
    }

    static func completedJobs(_ jobs: [Job]) -> [Job] {
        jobs
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
}
