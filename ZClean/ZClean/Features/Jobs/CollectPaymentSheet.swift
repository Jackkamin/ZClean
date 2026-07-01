import SwiftUI

struct CollectPaymentSheet: View {
    let clientName: String
    let suggestedAmount: Double
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String

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
                        guard let amount = Double(amountText), amount > 0 else { return }
                        onConfirm(amount)
                        dismiss()
                    }
                    .disabled(Double(amountText) == nil)
                }
            }
        }
    }
}
