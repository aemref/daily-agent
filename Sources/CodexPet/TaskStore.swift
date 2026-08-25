import Foundation
import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var plan: RoadmapDay
    @Published private(set) var tasks: [DailyTask]
    @Published private(set) var completedDateKeys: Set<String>
    @Published private(set) var activeRoadmap: GeneratedRoadmap?
    @Published private(set) var roadmapStartDate: Date?

    private let engine: RoadmapEngine
    private let customScheduler: CustomRoadmapScheduler
    private let now: () -> Date
    private let stateURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        engine: RoadmapEngine = RoadmapEngine(),
        customScheduler: CustomRoadmapScheduler = CustomRoadmapScheduler(),
        now: @escaping () -> Date = Date.init,
        stateURL: URL? = nil
    ) {
        self.engine = engine
        self.customScheduler = customScheduler
        self.now = now
        let today = now()
        let initialPlan = engine.plan(for: today)
        self.plan = initialPlan
        self.tasks = initialPlan.tasks
        self.completedDateKeys = []
        self.activeRoadmap = nil
        self.roadmapStartDate = nil
        self.stateURL = stateURL ?? Self.defaultStateURL
        loadOrGenerate(for: today)
    }

    var completedCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var hasActiveRoadmap: Bool {
        activeRoadmap != nil
    }

    var roadmapTitle: String {
        activeRoadmap?.title ?? "Daily Agent"
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    var isDayComplete: Bool {
        !tasks.isEmpty && tasks.allSatisfy(\.isCompleted)
    }

    var currentStreak: Int {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: now())
        var cursor = isDayComplete ? today : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var count = 0

        while completedDateKeys.contains(Self.dateKey(for: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    func setCompleted(_ completed: Bool, taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].isCompleted = completed
        synchronizeCompletionState()
        save()
    }

    func refreshIfNeeded() {
        loadOrGenerate(for: now())
    }

    func activate(_ roadmap: GeneratedRoadmap) {
        let today = now()
        activeRoadmap = roadmap
        roadmapStartDate = Calendar.autoupdatingCurrent.startOfDay(for: today)
        plan = currentPlan(for: today)
        tasks = plan.tasks
        synchronizeCompletionState()
        save()
    }

    func resetRoadmap() {
        activeRoadmap = nil
        roadmapStartDate = nil
        plan = engine.plan(for: now())
        tasks = []
        save()
    }

    private func loadOrGenerate(for date: Date) {
        let key = Self.dateKey(for: date)

        guard
            let data = try? Data(contentsOf: stateURL),
            let state = try? decoder.decode(PersistedState.self, from: data)
        else {
            plan = engine.plan(for: date)
            tasks = []
            completedDateKeys = []
            save()
            return
        }

        completedDateKeys = Set(state.completedDateKeys)
        activeRoadmap = state.activeRoadmap
        roadmapStartDate = state.roadmapStartDate
        plan = currentPlan(for: date)
        tasks = state.dateKey == key ? state.tasks : plan.tasks
        synchronizeCompletionState()
        save()
    }

    private func currentPlan(for date: Date) -> RoadmapDay {
        guard let activeRoadmap, let roadmapStartDate else {
            return engine.plan(for: date)
        }
        return customScheduler.plan(
            for: date,
            roadmap: activeRoadmap,
            startDate: roadmapStartDate
        )
    }

    private func synchronizeCompletionState() {
        let key = Self.dateKey(for: now())
        if isDayComplete {
            completedDateKeys.insert(key)
        } else {
            completedDateKeys.remove(key)
        }
    }

    private func save() {
        let state = PersistedState(
            dateKey: Self.dateKey(for: now()),
            tasks: tasks,
            completedDateKeys: completedDateKeys.sorted(),
            activeRoadmap: activeRoadmap,
            roadmapStartDate: roadmapStartDate
        )
        guard let data = try? encoder.encode(state) else { return }
        do {
            try FileManager.default.createDirectory(
                at: stateURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: stateURL, options: .atomic)
        } catch {
            assertionFailure("Codex Pet state could not be saved: \(error)")
        }
    }

    private static var defaultStateURL: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupport
            .appendingPathComponent("CodexRoadmapPet", isDirectory: true)
            .appendingPathComponent("state.json")
    }

    static func dateKey(for date: Date) -> String {
        date.formatted(.iso8601.year().month().day())
    }
}
