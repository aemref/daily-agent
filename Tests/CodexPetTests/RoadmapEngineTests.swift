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

    func testEnvironmentParserSupportsQuotesAndComments() {
        let values = EnvironmentLoader.parse(
            """
            # local only
            OPENAI_API_KEY="test-key"
            OPENAI_MODEL=gpt-test
            """
        )

        XCTAssertEqual(values["OPENAI_API_KEY"], "test-key")
        XCTAssertEqual(values["OPENAI_MODEL"], "gpt-test")
    }

    func testCustomRoadmapSchedulerDistributesTasksAcrossDays() throws {
        let roadmap = GeneratedRoadmap(
            title: "Test Roadmap",
            summary: "Test",
            durationWeeks: 1,
            daysPerWeek: 5,
            minutesPerDay: 60,
            weeks: [
                GeneratedWeek(
                    weekNumber: 1,
                    milestone: "Foundation",
                    theme: "Basics",
                    outcome: "Working baseline",
                    tasks: (1...10).map {
                        GeneratedTask(
                            title: "Task \($0)",
                            detail: "Detail",
                            category: "build",
                            estimatedMinutes: 30,
                            acceptanceCriteria: ["Done"]
                        )
                    }
                )
            ]
        )
        let calendar = Calendar(identifier: .gregorian)
        let start = RoadmapEngine.startDate
        let secondDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: start))
        let plan = CustomRoadmapScheduler(calendar: calendar).plan(
            for: secondDay,
            roadmap: roadmap,
            startDate: start
        )

        XCTAssertEqual(plan.dayNumber, 2)
        XCTAssertEqual(plan.totalDays, 7)
        XCTAssertEqual(plan.tasks.map(\.title), ["Task 2", "Task 7"])
    }
}
