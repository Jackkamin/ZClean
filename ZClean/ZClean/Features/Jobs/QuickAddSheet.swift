import SwiftUI

struct QuickAddSheet: View {
    enum Mode: String, CaseIterable, Identifiable {
        case addJob = "Add Job"
        case gotPaid = "Get Paid"

        var id: String { rawValue }
    }

    let recentNames: [String]
    let onAddJob: (AddJobInput) -> Void
    let onGotPaid: (GotPaidInput) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .addJob
    @State private var name = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var includeTime = false
    @State private var time = Date()
    @State private var durationHours = 2
    @State private var isWeekly = false
    @State private var recurrenceWeekdays: Set<Int> = []

    private var parsedAmount: Double? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        return Double(normalized)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (parsedAmount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Client name", text: $name)
                        .textInputAutocapitalization(.words)

                    if !recentNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentNames, id: \.self) { recent in
                                    Button(recent) { name = recent }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                } header: {
                    Label("Client", systemImage: "person.crop.circle")
                }

                Section {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                } header: {
                    Label("Payment", systemImage: "sterlingsign.circle.fill")
                }

                if mode == .addJob {
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
            }
            .navigationTitle("Quick add")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .addJob ? "Save Job" : "Save Payment") {
                        guard let amount = parsedAmount, amount > 0 else { return }
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

                        if mode == .addJob {
                            onAddJob(
                                AddJobInput(
                                    clientName: trimmedName,
                                    amount: amount,
                                    date: date,
                                    time: includeTime ? time : nil,
                                    durationHours: durationHours,
                                    recurrenceWeekdays: isWeekly ? recurrenceWeekdays.sorted() : [],
                                    isWeekly: isWeekly
                                )
                            )
                        } else {
                            onGotPaid(
                                GotPaidInput(
                                    clientName: trimmedName,
                                    amount: amount
                                )
                            )
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if recurrenceWeekdays.isEmpty {
                    recurrenceWeekdays = [Calendar.current.component(.weekday, from: date)]
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
