import SwiftUI

struct AddJobInput {
    var clientName: String
    var amount: Double
    var date: Date
    var time: Date?
    var durationHours: Int
    var isWeekly: Bool
}

struct AddJobSheet: View {
    let recentNames: [String]
    let onSave: (AddJobInput) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var includeTime = false
    @State private var time = Date()
    @State private var durationHours = 2
    @State private var isWeekly = false

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
                            amount: amount,
                            date: date,
                            time: includeTime ? time : nil,
                            durationHours: durationHours,
                            isWeekly: isWeekly
                        )
                        onSave(input)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedAmount == nil)
                }
            }
        }
    }
}
