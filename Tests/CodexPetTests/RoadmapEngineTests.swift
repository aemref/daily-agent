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
            daysPerWeek: 2,
            minutesPerDay: nil,
            selectedWeekdays: [2, 4],
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
                            estimatedMinutes: nil,
                            acceptanceCriteria: ["Done"]
                        )
                    }
                )
            ]
        )
        let calendar = Calendar(identifier: .gregorian)
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 24)))
        let secondDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: start))
        let plan = CustomRoadmapScheduler(calendar: calendar).plan(
            for: secondDay,
            roadmap: roadmap,
            startDate: start
        )

        XCTAssertEqual(plan.dayNumber, 2)
        XCTAssertEqual(plan.totalDays, 365)
        XCTAssertEqual(plan.tasks.map(\.title), ["Task 1", "Task 3", "Task 5", "Task 7", "Task 9"])
        XCTAssertEqual(plan.tasks.first?.detail, "Detail")
        XCTAssertEqual(plan.tasks.first?.checklist, ["Done"])
        XCTAssertEqual(plan.tasks.first?.completionCriteria, "Done")

        let restDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 2, to: start))
        let restPlan = CustomRoadmapScheduler(calendar: calendar).plan(
            for: restDay,
            roadmap: roadmap,
            startDate: start
        )
        XCTAssertTrue(restPlan.tasks.isEmpty)
    }

    @MainActor
    func testIncompleteGeneratedTaskCarriesIntoDatedBacklog() throws {
        let calendar = Calendar(identifier: .gregorian)
        let dayOne = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 24)))
        let dayTwo = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: dayOne))
        let stateURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("daily-agent-public-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: stateURL) }

        let roadmap = generatedRoadmapForPersistenceTests()
        let firstStore = TaskStore(now: { dayOne }, stateURL: stateURL)
        firstStore.activate(roadmap)
        XCTAssertEqual(firstStore.tasks.map(\.title), ["Task 1"])

        let secondStore = TaskStore(now: { dayTwo }, stateURL: stateURL)
        XCTAssertEqual(secondStore.tasks.map(\.title), ["Task 2"])
        XCTAssertEqual(secondStore.overdueTasks.map(\.title), ["Task 1"])
        XCTAssertEqual(secondStore.overdueTasks.first?.scheduledDateKey, TaskStore.dateKey(for: dayOne))

        let overdueID = try XCTUnwrap(secondStore.overdueTasks.first?.id)
        secondStore.completeOverdue(taskID: overdueID)
        XCTAssertTrue(secondStore.overdueTasks.isEmpty)
    }

    @MainActor
    func testCustomTaskAndDescriptionPersist() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 24)))
        let stateURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("daily-agent-custom-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: stateURL) }

        let store = TaskStore(now: { today }, stateURL: stateURL)
        store.activate(generatedRoadmapForPersistenceTests())
        XCTAssertTrue(
            store.addTask(
                title: "  README demosunu kaydet  ",
                detail: "  Kurulum ve sonuç akışını göster.  ",
                category: .review
            )
        )

        let reloaded = TaskStore(now: { today }, stateURL: stateURL)
        let custom = try XCTUnwrap(reloaded.tasks.last)
        XCTAssertEqual(custom.title, "README demosunu kaydet")
        XCTAssertEqual(custom.detail, "Kurulum ve sonuç akışını göster.")
        XCTAssertEqual(custom.category, .review)
        XCTAssertEqual(custom.scheduledDateKey, TaskStore.dateKey(for: today))
    }

    private func generatedRoadmapForPersistenceTests() -> GeneratedRoadmap {
        GeneratedRoadmap(
            title: "Persistence Test",
            summary: "Test",
            durationWeeks: 1,
            daysPerWeek: 7,
            minutesPerDay: nil,
            selectedWeekdays: Array(1...7),
            weeks: [
                GeneratedWeek(
                    weekNumber: 1,
                    milestone: "Foundation",
                    theme: "Basics",
                    outcome: "Working baseline",
                    tasks: [
                        GeneratedTask(
                            title: "Task 1",
                            detail: "First detail",
                            category: "build",
                            estimatedMinutes: nil,
                            acceptanceCriteria: ["First done"]
                        ),
                        GeneratedTask(
                            title: "Task 2",
                            detail: "Second detail",
                            category: "test",
                            estimatedMinutes: nil,
                            acceptanceCriteria: ["Second done"]
                        )
                    ]
                )
            ]
        )
    }
}
