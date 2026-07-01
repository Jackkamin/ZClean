import SwiftUI

struct EditJobInput {
    var amount: Double
    var date: Date
    var time: Date?
    var durationHours: Int
    var recurrenceWeekdays: [Int]
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
    @State private var recurrenceWeekdays: Set<Int>

    private var parsedAmount: Double? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        return Double(normalized)
    }

    init(job: Job, onSave: @escaping (EditJobInput) -> Void) {
        self.job = job
        self.onSave = onSave
        _amountText = State(initialValue: String(format: "%.2f", job.expectedAmount))
        _date = State(initialValue: job.scheduledDate)
        _includeTime = State(initialValue: job.scheduledTime != nil)
        _time = State(initialValue: job.scheduledTime ?? .now)
        _durationHours = State(initialValue: job.durationHours)
        _isWeekly = State(initialValue: job.isWeekly)
        let defaults = job.recurrenceWeekdays
        _recurrenceWeekdays = State(initialValue: Set(defaults.isEmpty ? [Calendar.current.component(.weekday, from: job.scheduledDate)] : defaults))
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
                    if isWeekly {
                        weekdayPicker
                    }
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
                        guard let amount = parsedAmount, amount > 0 else { return }
                        onSave(
                            EditJobInput(
                                amount: amount,
                                date: date,
                                time: includeTime ? time : nil,
                                durationHours: durationHours,
                                recurrenceWeekdays: isWeekly ? recurrenceWeekdays.sorted() : [],
                                isWeekly: isWeekly
                            )
                        )
                        dismiss()
                    }
                    .disabled(parsedAmount == nil)
                }
            }
            .onChange(of: date) { _, newDate in
                if isWeekly && recurrenceWeekdays.isEmpty {
                    recurrenceWeekdays = [Calendar.current.component(.weekday, from: newDate)]
                }
            }
            .onChange(of: isWeekly) { _, weekly in
                if weekly && recurrenceWeekdays.isEmpty {
                    recurrenceWeekdays = [Calendar.current.component(.weekday, from: date)]
                }
            }
        }
    }

    private var weekdayPicker: some View {
        let weekdays = Array(1...7)
        let symbols = DateFormatter().shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Repeats on")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(weekdays, id: \.self) { day in
                    let selected = recurrenceWeekdays.contains(day)
                    Button(symbols[day - 1]) {
                        if selected {
                            recurrenceWeekdays.remove(day)
                            if recurrenceWeekdays.isEmpty {
                                recurrenceWeekdays.insert(day)
                            }
                        } else {
                            recurrenceWeekdays.insert(day)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(selected ? .blue : .gray)
                }
            }
        }
    }
}
