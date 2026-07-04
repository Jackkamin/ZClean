import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    func scheduleReminder(for job: Job, contactName: String) async -> String? {
        await requestAuthorizationIfNeeded()
        guard let triggerDate = triggerDate(for: job) else { return nil }
        guard triggerDate > .now else { return nil }

        let identifier = job.notificationId ?? UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = "Upcoming cleaning job"
        content.body = "\(contactName) · \(Currency.gbp(job.expectedAmount))"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            return identifier
        } catch {
            return nil
        }
    }

    func cancelNotification(id: String?) {
        guard let id else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    private func triggerDate(for job: Job) -> Date? {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: job.scheduledDate)

        if let time = job.scheduledTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            guard let scheduledAt = calendar.date(
                bySettingHour: timeComponents.hour ?? 9,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: day
            ) else {
                return nil
            }
            return calendar.date(byAdding: .hour, value: -1, to: scheduledAt)
        }

        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day)
    }
}
