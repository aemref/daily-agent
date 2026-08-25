import XCTest
@testable import CodexPet

final class RoadmapEngineTests: XCTestCase {
    func testStartDateIsDayOneAndMonthOne() throws {
        let plan = RoadmapEngine().plan(for: RoadmapEngine.startDate)

        XCTAssertEqual(plan.dayNumber, 1)
        XCTAssertEqual(plan.monthNumber, 1)
        XCTAssertEqual(plan.milestone, "Q1")
        XCTAssertEqual(plan.repository, "production-ml-classifier")
        XCTAssertEqual(plan.tasks.count, 3)
    }

    func testLastDayMapsToMonthTwelveAndQFour() throws {
        let calendar = Calendar(identifier: .gregorian)
        let finalDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 364, to: RoadmapEngine.startDate))
        let plan = RoadmapEngine(calendar: calendar).plan(for: finalDay)

        XCTAssertEqual(plan.dayNumber, 365)
        XCTAssertEqual(plan.monthNumber, 12)
        XCTAssertEqual(plan.milestone, "Q4")
        XCTAssertEqual(plan.repository, "multilingual-learning-copilot")
    }

    func testEveryMonthHasSevenWeekdayTasks() {
        XCTAssertEqual(RoadmapEngine.months.count, 12)
        XCTAssertTrue(RoadmapEngine.months.allSatisfy { $0.weekdayTasks.count == 7 })
    }
}
