import SwiftUI

struct AddJobInput {
    var clientName: String
    var jobDescription: String = ""
    var amount: Double
    var date: Date
    var time: Date?
    var durationHours: Int
    var recurrenceWeekdays: [Int]
    var isWeekly: Bool
}

struct AddJobSheet: View {
    let recentNames: [String]
    let onSave: (AddJobInput) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var jobDescription = ""
    @State private var amountText = ""
    @State private var date = Date()
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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Client name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Description (optional)", text: $jobDescription, axis: .vertical)
                        .lineLimit(2...4)

                    if !recentNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentNames, id: \.self) { recent in
                                    Button(recent) {
                                        name = recent
                                    }
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

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TimePresetPicker(selectedTime: $time)
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
            .navigationTitle("Add job")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = parsedAmount, amount > 0 else { return }
                        let input = AddJobInput(
                            clientName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            jobDescription: jobDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: amount,
                            date: date,
                            time: time,
                            durationHours: durationHours,
                            recurrenceWeekdays: isWeekly ? recurrenceWeekdays.sorted() : [],
                            isWeekly: isWeekly
                        )
                        onSave(input)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedAmount == nil)
                }
            }
            .onAppear {
                snapTimeToPresetIfNeeded()
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

    private func snapTimeToPresetIfNeeded() {
        let presetHours = [9, 10, 11, 12, 13, 14, 15, 16]
        let selectedHour = Calendar.current.component(.hour, from: time)
        guard !presetHours.contains(selectedHour) else { return }
        time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: time) ?? time
    }

    private var weekdayPicker: some View {
        let weekdays = Array(1...7)
        let symbols = DateFormatter().shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                ForEach(weekdays, id: \.self) { day in
                    weekdayButton(day: day, label: symbols[day - 1])
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(weekdays, id: \.self) { day in
                    weekdayButton(day: day, label: symbols[day - 1])
                }
            }
        }
    }

    @ViewBuilder
    private func weekdayButton(day: Int, label: String) -> some View {
        let selected = recurrenceWeekdays.contains(day)
        Button(label) {
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
        .font(.caption.weight(.semibold))
        .frame(minWidth: 40)
    }
}
