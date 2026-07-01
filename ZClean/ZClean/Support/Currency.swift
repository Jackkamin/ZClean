import Foundation

enum Currency {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let wholePoundsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func gbp(_ amount: Double) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? "£0.00"
    }

    static func gbpWhole(_ amount: Double) -> String {
        wholePoundsFormatter.string(from: NSNumber(value: amount)) ?? "£0"
    }
}
