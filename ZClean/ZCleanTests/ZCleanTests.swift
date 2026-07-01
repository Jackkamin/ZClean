import XCTest
@testable import ZClean

final class ZCleanTests: XCTestCase {

    // MARK: - Helpers

    private func makeJob(
        hoursFromNow: Double,
        isWeekly: Bool = false,
        status: JobStatus = .upcoming,
        cashAmount: Double? = nil,
        completedAt: Date? = nil,
        expectedAmount: Double = 50
    ) -> Job {
        let scheduledAt = Date().addingTimeInterval(hoursFromNow * 3600)
        return Job(
            scheduledDate: scheduledAt,
            scheduledTime: scheduledAt,
            durationHours: 2,
            expectedAmount: expectedAmount,
            cashAmount: cashAmount,
            isWeekly: isWeekly,
            status: status,
            completedAt: completedAt
        )
    }

    // MARK: - Upcoming jobs sorting

    @MainActor
    func testUpcomingJobsSortsClosestFirst() {
        let farJob = makeJob(hoursFromNow: 72)
        let nearJob = makeJob(hoursFromNow: 3)
        let midJob = makeJob(hoursFromNow: 30)

        let sorted = JobStore.upcomingJobs([farJob, nearJob, midJob])

        XCTAssertEqual(sorted.count, 3)
        XCTAssertIdentical(sorted[0], nearJob)
        XCTAssertIdentical(sorted[1], midJob)
        XCTAssertIdentical(sorted[2], farJob)
    }

    @MainActor
    func testUpcomingJobsExcludesCompletedJobs() {
        let upcoming = makeJob(hoursFromNow: 5)
        let completed = makeJob(hoursFromNow: 2, status: .completed, completedAt: .now)

        let result = JobStore.upcomingJobs([upcoming, completed])

        XCTAssertEqual(result.count, 1)
        XCTAssertIdentical(result[0], upcoming)
    }

    @MainActor
    func testWeeklyJobHiddenUntil24HoursBefore() {
        let weeklyFarOut = makeJob(hoursFromNow: 72, isWeekly: true)
        let weeklySoon = makeJob(hoursFromNow: 10, isWeekly: true)

        let result = JobStore.upcomingJobs([weeklyFarOut, weeklySoon])

        XCTAssertEqual(result.count, 1)
        XCTAssertIdentical(result[0], weeklySoon)
    }

    // MARK: - Monthly earnings

    @MainActor
    func testThisMonthEarningsSumsOnlyCompletedJobsThisMonth() {
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: .now)!

        let paidThisMonth = makeJob(
            hoursFromNow: -2,
            status: .completed,
            cashAmount: 80,
            completedAt: .now
        )
        let paidLastMonth = makeJob(
            hoursFromNow: -700,
            status: .completed,
            cashAmount: 60,
            completedAt: lastMonth
        )
        let notPaidYet = makeJob(hoursFromNow: 5)

        let total = JobStore.thisMonthEarnings(from: [paidThisMonth, paidLastMonth, notPaidYet])

        XCTAssertEqual(total, 80, accuracy: 0.001)
    }

    // MARK: - Recurrence weekday serialization

    func testRecurrenceWeekdaysFiltersInvalidAndDuplicateValues() {
        let job = Job(
            scheduledDate: .now,
            recurrenceWeekdays: [3, 3, 9, 0, 1],
            expectedAmount: 40
        )

        XCTAssertEqual(job.recurrenceWeekdays, [1, 3])
    }

    func testRecurrenceWeekdaysRoundTrip() {
        let job = Job(scheduledDate: .now, expectedAmount: 40)
        job.recurrenceWeekdays = [6, 2, 4]

        XCTAssertEqual(job.recurrenceWeekdays, [2, 4, 6])
        XCTAssertEqual(job.recurrenceWeekdaysRaw, "2,4,6")
    }
}
