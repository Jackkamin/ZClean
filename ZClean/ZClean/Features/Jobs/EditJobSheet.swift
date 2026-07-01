import SwiftUI

struct EditJobInput {
    var amount: Double
    var date: Date
    var time: Date?
    var durationHours: Int
    var isWeekly: Bool
}

struct EditJobSheet: View {
    let job: Job
    let onSave: (EditJobInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String
    @State private var date: Date
    @State private var includeTime: Bool
    @State private var time: Date
    @State private var durationHours: Int
    @State private var isWeekly: Bool

    init(job: Job, onSave: @escaping (EditJobInput) -> Void) {
        self.job = job
        self.onSave = onSave
        _amountText = State(initialValue: String(format: "%.2f", job.expectedAmount))
        _date = State(initialValue: job.scheduledDate)
        _includeTime = State(initialValue: job.scheduledTime != nil)
        _time = State(initialValue: job.scheduledTime ?? .now)
        _durationHours = State(initialValue: job.durationHours)
        _isWeekly = State(initialValue: job.isWeekly)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                } header: {
                    Label("Payment", systemImage: "sterlingsign.circle.fill")
                }
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Set a time", isOn: $includeTime)
                    if includeTime {
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    Stepper(value: $durationHours, in: 1...4) {
                        Label("\(durationHours) \(durationHours == 1 ? "hour" : "hours")", systemImage: "clock")
                    }
                    Toggle("Weekly repeat", isOn: $isWeekly)
                } header: {
                    Label("When", systemImage: "calendar.badge.clock")
                }
            }
            .navigationTitle("Edit job")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = Double(amountText), amount > 0 else { return }
                        onSave(
                            EditJobInput(
                                amount: amount,
                                date: date,
                                time: includeTime ? time : nil,
                                durationHours: durationHours,
                                isWeekly: isWeekly
                            )
                        )
                        dismiss()
                    }
                    .disabled(Double(amountText) == nil)
                }
            }
        }
    }
}
