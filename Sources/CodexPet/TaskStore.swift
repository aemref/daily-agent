import Foundation
import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var plan: RoadmapDay
    @Published private(set) var tasks: [DailyTask]
    @Published private(set) var completedDateKeys: Set<String>

    private let engine: RoadmapEngine
    private let now: () -> Date
    private let stateURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        engine: RoadmapEngine = RoadmapEngine(),
        now: @escaping () -> Date = Date.init,
        stateURL: URL? = nil
    ) {
        self.engine = engine
        self.now = now
        let today = now()
        let initialPlan = engine.plan(for: today)
        self.plan = initialPlan
        self.tasks = initialPlan.tasks
        self.completedDateKeys = []
        self.stateURL = stateURL ?? Self.defaultStateURL
        loadOrGenerate(for: today)
    }

    var completedCount: Int {
        tasks.filter(\.isCompleted).count
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

    private func loadOrGenerate(for date: Date) {
        let key = Self.dateKey(for: date)
        plan = engine.plan(for: date)

        guard
            let data = try? Data(contentsOf: stateURL),
            let state = try? decoder.decode(PersistedState.self, from: data)
        else {
            tasks = plan.tasks
            completedDateKeys = []
            save()
            return
        }

        completedDateKeys = Set(state.completedDateKeys)
        tasks = state.dateKey == key ? state.tasks : plan.tasks
        synchronizeCompletionState()
        save()
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
            completedDateKeys: completedDateKeys.sorted()
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
