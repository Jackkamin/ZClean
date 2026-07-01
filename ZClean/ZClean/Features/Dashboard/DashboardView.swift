import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var jobs: [Job]
    @Query private var contacts: [Contact]

    @State private var showingAddJob = false
    @State private var pendingCollectJob: Job?
    @State private var selectedForEdit: Job?
    @State private var showingEditSheet = false
    @State private var deletingJob: Job?
    @State private var monthTotal = 0.0
    @State private var monthTotalAnimationTask: Task<Void, Never>?
    @State private var saveErrorMessage: String?
    @State private var showPaymentConfirm = false
    @State private var paymentConfirmScale: CGFloat = 0.88
    @State private var paymentConfirmOpacity: Double = 0
    @State private var paymentConfirmTask: Task<Void, Never>?

    private var upcomingJobs: [Job] {
        JobStore.upcomingJobs(jobs)
    }

    private var completedJobs: [Job] {
        JobStore.completedJobs(jobs)
    }

    private var recentHistory: [Job] {
        Array(completedJobs.prefix(3))
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

    private var showingDeleteAlertBinding: Binding<Bool> {
        Binding(
            get: { deletingJob != nil },
            set: { newValue in
                if !newValue {
                    deletingJob = nil
                }
            }
        )
    }

    private var showingCollectAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingCollectJob != nil },
            set: { newValue in
                if !newValue {
                    pendingCollectJob = nil
                }
            }
        )
    }

    private var showingSaveErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    saveErrorMessage = nil
                }
            }
        )
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            Section {
                if upcomingJobs.isEmpty {
                    ContentUnavailableView(
                        "No jobs today",
                        systemImage: "calendar.badge.plus",
                        description: Text("Tap + to add a job or record payment.")
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
                                pendingCollectJob = job
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

            Section {
                if recentHistory.isEmpty {
                    Text("No recent payments yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                } else {
                    ForEach(recentHistory) { job in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(JobStore.decryptedName(for: job.contact))
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text((job.completedAt ?? job.createdAt), format: .dateTime.day().month(.abbreviated))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Currency.gbp(job.cashAmount ?? job.expectedAmount))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 2)
                    }
                }

                NavigationLink {
                    HistoryView(jobs: completedJobs)
                } label: {
                    Text("More...")
                        .font(.subheadline.weight(.semibold))
                }
            } header: {
                Label("Recent payments", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ManageJobsView(
                        jobs: jobs,
                        onEdit: { job, input in
                            edit(job: job, with: input)
                        },
                        onDelete: { job in
                            NotificationService.shared.cancelNotification(id: job.notificationId)
                            context.delete(job)
                            do {
                                try context.save()
                                refreshMonthTotal()
                            } catch {
                                saveErrorMessage = "Failed to delete this job. \(error.localizedDescription)"
                            }
                        }
                    )
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.3")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showingAddJob = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Add a new cleaning job or record payment")
                Spacer()
            }
        }
        .sheet(isPresented: $showingAddJob) {
            QuickAddSheet(
                recentNames: recentNames,
                onAddJob: addJob,
                onGotPaid: gotPaid
            )
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
            isPresented: showingDeleteAlertBinding,
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
            "Collect payment?",
            isPresented: showingCollectAlertBinding,
            presenting: pendingCollectJob
        ) { job in
            Button("Confirm") {
                collectPayment(job: job, amount: job.expectedAmount)
                pendingCollectJob = nil
            }
            Button("Cancel", role: .cancel) {
                pendingCollectJob = nil
            }
        } message: { job in
            Text("Collected \(Currency.gbp(job.expectedAmount)) from \(JobStore.decryptedName(for: job.contact))?")
        }
        .alert(
            "Couldn’t save",
            isPresented: showingSaveErrorAlertBinding
        ) {
            Button("OK", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
        .overlay {
            if showPaymentConfirm {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 86, weight: .regular))
                        .foregroundStyle(.green)
                    Text("Payment Sent")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .scaleEffect(paymentConfirmScale)
                .opacity(paymentConfirmOpacity)
                .compositingGroup()
                .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.22), value: paymentConfirmScale)
        .animation(.easeOut(duration: 0.22), value: paymentConfirmOpacity)
        .task {
            refreshMonthTotal(animated: false)
        }
        .onChange(of: jobs.count) { _, _ in
            refreshMonthTotal()
        }
    }

    private func refreshMonthTotal(animated: Bool = true) {
        let target = JobStore.thisMonthEarnings(from: jobs)
        guard animated else {
            monthTotalAnimationTask?.cancel()
            monthTotal = target
            return
        }
        animateMonthTotal(to: target)
    }

    private func animateMonthTotal(to target: Double, duration: Double = 0.75) {
        monthTotalAnimationTask?.cancel()
        let start = monthTotal
        let delta = target - start
        guard abs(delta) > 0.005 else {
            monthTotal = target
            return
        }

        monthTotalAnimationTask = Task { @MainActor in
            let frames = 30
            for frame in 1...frames {
                if Task.isCancelled { return }
                let t = Double(frame) / Double(frames)
                // Smooth easing for a fintech-like balance count-up.
                let eased = 1 - pow(1 - t, 3)
                monthTotal = start + (delta * eased)
                try? await Task.sleep(
                    nanoseconds: UInt64((duration / Double(frames)) * 1_000_000_000)
                )
            }
            monthTotal = target
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
                recurrenceWeekdays: input.recurrenceWeekdays,
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
            let nextDate = nextRecurringDate(for: job)
            let nextJob = Job(
                contact: job.contact,
                scheduledDate: nextDate,
                scheduledTime: job.scheduledTime,
                durationHours: job.durationHours,
                recurrenceWeekdays: job.recurrenceWeekdays,
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
            playPaymentSentAnimation()
        } catch {
            saveErrorMessage = "Failed to collect payment. \(error.localizedDescription)"
        }
    }

    private func edit(job: Job, with input: EditJobInput) {
        job.expectedAmount = input.amount
        job.scheduledDate = input.date
        job.scheduledTime = input.time
        job.durationHours = input.durationHours
        job.recurrenceWeekdays = input.recurrenceWeekdays
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

    private func nextRecurringDate(for job: Job) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: job.scheduledDate)
        let selected = job.recurrenceWeekdays.isEmpty
            ? [calendar.component(.weekday, from: start)]
            : job.recurrenceWeekdays
        let currentWeekday = calendar.component(.weekday, from: start)
        let nextOffset = selected
            .map { day -> Int in
                let delta = (day - currentWeekday + 7) % 7
                return delta == 0 ? 7 : delta
            }
            .min() ?? 7

        return calendar.date(byAdding: .day, value: nextOffset, to: start) ?? start
    }

    private func playPaymentSentAnimation() {
        paymentConfirmTask?.cancel()
        showPaymentConfirm = true
        paymentConfirmScale = 0.88
        paymentConfirmOpacity = 0

        withAnimation {
            paymentConfirmScale = 1
            paymentConfirmOpacity = 1
        }

        paymentConfirmTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            withAnimation {
                paymentConfirmScale = 1.02
            }
            try? await Task.sleep(nanoseconds: 450_000_000)
            withAnimation {
                paymentConfirmOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 220_000_000)
            showPaymentConfirm = false
        }
    }
}
