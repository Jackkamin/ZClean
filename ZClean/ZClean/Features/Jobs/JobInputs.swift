import Foundation

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

struct GotPaidInput {
    var clientName: String
    var amount: Double
}
