import SwiftUI
import SwiftData

struct ManageJobsView: View {
    @Query private var jobs: [Job]
    let onEdit: (Job, EditJobInput) -> Void
    let onDelete: (Job) -> Void

    @State private var selectedJob: Job?
    @State private var showingEditSheet = false

    private var editableJobs: [Job] {
        return jobs
            // Always include all active jobs so none disappear from edit controls.
            .filter { $0.status == .upcoming }
            .sorted {
                let lhsUrgent = isUrgent($0)
                let rhsUrgent = isUrgent($1)
                if lhsUrgent != rhsUrgent {
                    return lhsUrgent && !rhsUrgent
                }
                return scheduledAt($0) < scheduledAt($1)
            }
    }

    var body: some View {
        List {
            if editableJobs.isEmpty {
                ContentUnavailableView(
                    "No active/future jobs",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Jobs you create will appear here for editing.")
                )
            } else {
                ForEach(editableJobs) { job in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(JobStore.decryptedName(for: job.contact))
                                .font(.headline)
                                .lineLimit(1)
                            if !job.jobDescription.isEmpty {
                                Text(job.jobDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
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

    private func isUrgent(_ job: Job) -> Bool {
        let now = Date()
        let dueAt = scheduledAt(job)
        guard dueAt >= now else { return false }
        let in24Hours = Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now
        return dueAt <= in24Hours
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
