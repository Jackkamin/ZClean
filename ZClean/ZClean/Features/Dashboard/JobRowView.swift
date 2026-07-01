import SwiftUI

struct JobRowView: View {
    let name: String
    let amount: Double
    let scheduledDate: Date
    let scheduledTime: Date?
    let durationHours: Int
    let onCollect: () -> Void

    @State private var pulse = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let urgency = urgencyLevel(now: timeline.date)
            let countdown = countdownText(now: timeline.date)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(dateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(shiftText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(countdown)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(countdownColor(urgency))
                }

                Spacer()

                Label {
                    Text(Currency.gbp(amount))
                        .font(.headline)
                } icon: {
                    Image(systemName: "sterlingsign.circle.fill")
                        .foregroundStyle(.yellow)
                }

                Button(action: onCollect) {
                    Label("Collect", systemImage: "coins")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(cardBackground(urgency))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect((urgency == .urgent || urgency == .overdue) ? (pulse ? 1.0 : 0.985) : 1.0)
            .animation(
                (urgency == .urgent || urgency == .overdue)
                    ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                    : .default,
                value: pulse
            )
            .onAppear {
                pulse = urgency == .urgent || urgency == .overdue
            }
        }
        .padding(.vertical, 6)
    }

    private var scheduledAt: Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: scheduledDate)
        if let scheduledTime {
            let comps = calendar.dateComponents([.hour, .minute], from: scheduledTime)
            return calendar.date(
                bySettingHour: comps.hour ?? 9,
                minute: comps.minute ?? 0,
                second: 0,
                of: day
            ) ?? day
        }
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
    }

    private var dateText: String {
        scheduledDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
    }

    private var shiftText: String {
        guard scheduledTime != nil else {
            return "Time not set • \(durationHours)h shift"
        }

        let start = scheduledAt.formatted(.dateTime.hour().minute())
        let end = Calendar.current.date(byAdding: .hour, value: durationHours, to: scheduledAt)?
            .formatted(.dateTime.hour().minute()) ?? "-"
        return "Shift \(start) - \(end) (\(durationHours)h)"
    }

    private enum UrgencyLevel {
        case normal
        case soon
        case urgent
        case overdue
    }

    private func urgencyLevel(now: Date) -> UrgencyLevel {
        let seconds = scheduledAt.timeIntervalSince(now)
        if seconds <= 0 { return .overdue }
        if seconds <= 90 * 60 { return .urgent }
        if seconds <= 12 * 3600 { return .soon }
        return .normal
    }

    private func countdownColor(_ urgency: UrgencyLevel) -> Color {
        switch urgency {
        case .normal:
            return .secondary
        case .soon:
            return .orange
        case .urgent, .overdue:
            return .red
        }
    }

    private func cardBackground(_ urgency: UrgencyLevel) -> Color {
        switch urgency {
        case .normal:
            return Color.secondary.opacity(0.08)
        case .soon:
            return Color.orange.opacity(0.12)
        case .urgent, .overdue:
            return Color.red.opacity(0.15)
        }
    }

    private func countdownText(now: Date) -> String {
        let diff = scheduledAt.timeIntervalSince(now)
        if diff <= 0 {
            return "Now due"
        }

        let minutes = max(1, Int(ceil(diff / 60)))
        if minutes < 60 {
            return "In \(minutes) mins"
        }

        let totalHours = max(1, Int(diff / 3600))
        if totalHours < 24 {
            return "In \(totalHours)h"
        }

        let calendar = Calendar.current
        if calendar.isDateInTomorrow(scheduledAt) {
            let hoursLeft = max(0, calendar.dateComponents([.hour], from: now, to: scheduledAt).hour ?? 0)
            return "Tomorrow in \(hoursLeft)h"
        }

        let components = calendar.dateComponents([.day, .hour], from: now, to: scheduledAt)
        let days = max(0, components.day ?? 0)
        let hours = max(0, components.hour ?? 0)
        return "In \(days)d \(hours)h"
    }
}
