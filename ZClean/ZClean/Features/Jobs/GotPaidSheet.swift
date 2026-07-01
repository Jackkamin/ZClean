import SwiftUI

struct GotPaidInput {
    var clientName: String
    var amount: Double
}

struct GotPaidSheet: View {
    let recentNames: [String]
    let onSave: (GotPaidInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var amountText = ""

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
            }
            .navigationTitle("Got paid")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = Double(amountText), amount > 0 else { return }
                        onSave(
                            GotPaidInput(
                                clientName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                amount: amount
                            )
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(amountText) == nil)
                }
            }
        }
    }
}
