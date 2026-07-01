import SwiftUI

struct TimePresetPicker: View {
    @Binding var selectedTime: Date

    private let presetHours = [9, 10, 11, 12, 13, 14, 15, 16]
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shift start")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presetHours, id: \.self) { hour in
                        let selected = calendar.component(.hour, from: selectedTime) == hour
                        Button(label(for: hour)) {
                            selectedTime = makeTime(hour: hour)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(selected ? .blue : .gray.opacity(0.55))
                        .font(.subheadline.weight(.semibold))
                        .frame(minWidth: 64)
                    }
                }
            }
        }
    }

    private func makeTime(hour: Int) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: selectedTime) ?? selectedTime
    }

    private func label(for hour: Int) -> String {
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))).lowercased()
    }
}
