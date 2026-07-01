import SwiftUI

struct CollectPaymentSheet: View {
    let clientName: String
    let suggestedAmount: Double
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String

    private var parsedAmount: Double? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        return Double(normalized)
    }

    init(clientName: String, suggestedAmount: Double, onConfirm: @escaping (Double) -> Void) {
        self.clientName = clientName
        self.suggestedAmount = suggestedAmount
        self.onConfirm = onConfirm
        _amountText = State(initialValue: String(format: "%.2f", suggestedAmount))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(clientName)
                        .font(.headline)
                } header: {
                    Label("Client", systemImage: "person.crop.circle")
                }
                Section {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                } header: {
                    Label("Amount collected", systemImage: "coins")
                }
            }
            .navigationTitle("Collect payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        guard let amount = parsedAmount, amount > 0 else { return }
                        onConfirm(amount)
                        dismiss()
                    }
                    .disabled(parsedAmount == nil)
                }
            }
        }
    }
}
