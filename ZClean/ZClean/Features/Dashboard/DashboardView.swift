import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var jobs: [Job]
    @Query private var contacts: [Contact]

    @State private var showingAddJob = false
    @State private var showingGotPaid = false
    @State private var selectedForCollect: Job?
    @State private var selectedForEdit: Job?
    @State private var showingCollectSheet = false
    @State private var showingEditSheet = false
    @State private var deletingJob: Job?
    @State private var monthTotal = 0.0
    @State private var saveErrorMessage: String?

    private var upcomingJobs: [Job] {
        JobStore.upcomingJobs(jobs)
    }

    private var completedJobs: [Job] {
        JobStore.completedJobs(jobs)
    }

    private var recentNames: [String] {
        let names = contacts.map { JobStore.decryptedName(for: $0) }
        var unique: [String] = []
        for name in names where !name.isEmpty {
            if !unique.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                unique.append(name)
            }
        }
        return Array(unique.prefix(8))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("This month", systemImage: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(Currency.gbp(monthTotal))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.35), value: monthTotal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            Section {
                if upcomingJobs.isEmpty {
                    ContentUnavailableView(
                        "No jobs today",
                        systemImage: "calendar.badge.plus",
                        description: Text("Add a job or tap Got paid.")
                    )
                } else {
                    ForEach(upcomingJobs) { job in
                        JobRowView(
                            name: JobStore.decryptedName(for: job.contact),
                            amount: job.expectedAmount,
                            scheduledDate: job.scheduledDate,
                            scheduledTime: job.scheduledTime,
                            durationHours: job.durationHours,
                            onCollect: {
                                selectedForCollect = job
                                showingCollectSheet = true
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedForEdit = job
                            showingEditSheet = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deletingJob = job
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Label("Jobs", systemImage: "house.fill")
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    HistoryView(jobs: completedJobs)
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showingAddJob = true
                } label: {
                    Label("Add job", systemImage: "plus.circle.fill")
                }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Add a new cleaning job")
                Spacer()
                Button {
                    showingGotPaid = true
                } label: {
                    Label("Got paid", systemImage: "sterlingsign.circle.fill")
                }
                    .buttonStyle(.bordered)
                    .accessibilityHint("Record cash without a scheduled job")
            }
        }
        .sheet(isPresented: $showingAddJob) {
            AddJobSheet(recentNames: recentNames, onSave: addJob)
        }
        .sheet(isPresented: $showingGotPaid) {
            GotPaidSheet(recentNames: recentNames, onSave: gotPaid)
        }
        .sheet(isPresented: $showingCollectSheet, onDismiss: {
            selectedForCollect = nil
        }) {
            if let job = selectedForCollect {
                CollectPaymentSheet(
                    clientName: JobStore.decryptedName(for: job.contact),
                    suggestedAmount: job.expectedAmount
                ) { collected in
                    collectPayment(job: job, amount: collected)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            selectedForEdit = nil
        }) {
            if let job = selectedForEdit {
                EditJobSheet(job: job) { input in
                    edit(job: job, with: input)
                }
            }
        }
        .alert(
            "Delete this job?",
            isPresented: Binding(
                get: { deletingJob != nil },
                set: { if !$0 { deletingJob = nil } }
            ),
            presenting: deletingJob
        ) { job in
            Button("Delete", role: .destructive) {
                NotificationService.shared.cancelNotification(id: job.notificationId)
                context.delete(job)
                try? context.save()
                refreshMonthTotal()
                deletingJob = nil
            }
            Button("Cancel", role: .cancel) {
                deletingJob = nil
            }
        } message: { _ in
            Text("This cannot be undone.")
        }
        .alert(
            "Couldn’t save",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
        .task {
            refreshMonthTotal()
        }
        .onChange(of: jobs.count) { _, _ in
            refreshMonthTotal()
        }
    }

    private func refreshMonthTotal() {
        withAnimation {
            monthTotal = JobStore.thisMonthEarnings(from: jobs)
        }
    }

    private func addJob(input: AddJobInput) {
        do {
            let contact = try JobStore.fetchOrCreateContact(named: input.clientName, context: context)
            let job = Job(
                contact: contact,
                scheduledDate: input.date,
                scheduledTime: input.time,
                durationHours: input.durationHours,
                expectedAmount: input.amount,
                isWeekly: input.isWeekly,
                status: .upcoming
            )
            context.insert(job)
            try context.save()

            Task { @MainActor in
                let name = JobStore.decryptedName(for: job.contact)
                let id = await NotificationService.shared.scheduleReminder(for: job, contactName: name)
                if id != nil {
                    job.notificationId = id
                    try? context.save()
                }
            }
        } catch {
            saveErrorMessage = "Failed to add this job. \(error.localizedDescription)"
        }
    }

    private func gotPaid(input: GotPaidInput) {
        do {
            let contact = try JobStore.fetchOrCreateContact(named: input.clientName, context: context)
            let paidJob = Job(
                contact: contact,
                scheduledDate: .now,
                durationHours: 1,
                expectedAmount: input.amount,
                cashAmount: input.amount,
                isWeekly: false,
                status: .completed,
                completedAt: .now
            )
            context.insert(paidJob)
            try context.save()
            refreshMonthTotal()
        } catch {
            saveErrorMessage = "Failed to record payment. \(error.localizedDescription)"
        }
    }

    private func collectPayment(job: Job, amount: Double) {
        job.cashAmount = amount
        job.completedAt = .now
        job.status = .completed
        NotificationService.shared.cancelNotification(id: job.notificationId)
        job.notificationId = nil

        if job.isWeekly {
            let nextDate = Calendar.current.date(byAdding: .day, value: 7, to: job.scheduledDate) ?? job.scheduledDate
            let nextJob = Job(
                contact: job.contact,
                scheduledDate: nextDate,
                scheduledTime: job.scheduledTime,
                durationHours: job.durationHours,
                expectedAmount: job.expectedAmount,
                isWeekly: true,
                status: .upcoming
            )
            context.insert(nextJob)

            Task { @MainActor in
                let name = JobStore.decryptedName(for: nextJob.contact)
                let id = await NotificationService.shared.scheduleReminder(for: nextJob, contactName: name)
                if id != nil {
                    nextJob.notificationId = id
                    try? context.save()
                }
            }
        }

        do {
            try context.save()
            refreshMonthTotal()
        } catch {
            saveErrorMessage = "Failed to collect payment. \(error.localizedDescription)"
        }
    }

    private func edit(job: Job, with input: EditJobInput) {
        job.expectedAmount = input.amount
        job.scheduledDate = input.date
        job.scheduledTime = input.time
        job.durationHours = input.durationHours
        job.isWeekly = input.isWeekly

        NotificationService.shared.cancelNotification(id: job.notificationId)
        job.notificationId = nil

        Task { @MainActor in
            let name = JobStore.decryptedName(for: job.contact)
            let id = await NotificationService.shared.scheduleReminder(for: job, contactName: name)
            if id != nil {
                job.notificationId = id
            }
            do {
                try context.save()
            } catch {
                saveErrorMessage = "Failed to update this job. \(error.localizedDescription)"
            }
        }
    }
}
