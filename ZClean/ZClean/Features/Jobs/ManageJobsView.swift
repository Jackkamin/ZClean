import SwiftUI

struct ManageJobsView: View {
    let jobs: [Job]
    let onEdit: (Job, EditJobInput) -> Void
    let onDelete: (Job) -> Void

    @State private var selectedJob: Job?
    @State private var showingEditSheet = false

    private var upcomingJobs: [Job] {
        jobs
            .filter { $0.status == .upcoming }
            .sorted {
                if Calendar.current.isDate($0.scheduledDate, inSameDayAs: $1.scheduledDate) {
                    return ($0.scheduledTime ?? .distantPast) < ($1.scheduledTime ?? .distantPast)
                }
                return $0.scheduledDate < $1.scheduledDate
            }
    }

    var body: some View {
        List {
            if upcomingJobs.isEmpty {
                ContentUnavailableView(
                    "No upcoming jobs",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Jobs you create will appear here for editing.")
                )
            } else {
                ForEach(upcomingJobs) { job in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(JobStore.decryptedName(for: job.contact))
                                .font(.headline)
                                .lineLimit(1)
                            Text(metadataText(for: job))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            if isHiddenBy24HourRule(job) {
                                Text("Hidden from dashboard until 24h before")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }

                        Spacer()

                        Button("Edit") {
                            selectedJob = job
                            showingEditSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(job)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit jobs")
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            selectedJob = nil
        }) {
            if let job = selectedJob {
                EditJobSheet(job: job) { input in
                    onEdit(job, input)
                }
            }
        }
    }

    private func metadataText(for job: Job) -> String {
        let datePart = job.scheduledDate.formatted(.dateTime.day().month(.abbreviated))
        let timePart = job.scheduledTime?.formatted(.dateTime.hour().minute()) ?? "No time"
        return "\(datePart) • \(timePart) • \(job.durationHours)h"
    }

    private func isHiddenBy24HourRule(_ job: Job) -> Bool {
        guard job.isWeekly else { return false }
        let showFrom = Calendar.current.date(byAdding: .hour, value: -24, to: scheduledAt(job)) ?? .distantPast
        return Date() < showFrom
    }

    private func scheduledAt(_ job: Job) -> Date {
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
