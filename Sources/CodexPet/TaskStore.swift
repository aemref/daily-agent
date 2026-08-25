import Foundation
import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var plan: RoadmapDay
    @Published private(set) var tasks: [DailyTask]
    @Published private(set) var overdueTasks: [DailyTask]
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
        self.overdueTasks = []
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
        var cursor = today
        if isScheduledWorkday(today), !isDayComplete {
            cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        var count = 0

        for _ in 0..<366 {
            if isScheduledWorkday(cursor) {
                if completedDateKeys.contains(Self.dateKey(for: cursor)) {
                    count += 1
                } else {
                    break
                }
            }
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

    @discardableResult
    func addTask(title: String, detail: String, category: TaskCategory) -> Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, !cleanDetail.isEmpty else { return false }

        tasks.append(
            DailyTask(
                title: cleanTitle,
                detail: cleanDetail,
                category: category,
                estimatedMinutes: 0,
                scheduledDateKey: Self.dateKey(for: now())
            )
        )
        synchronizeCompletionState()
        save()
        return true
    }

    func completeOverdue(taskID: UUID) {
        overdueTasks.removeAll { $0.id == taskID }
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
        tasks = dated(plan.tasks, dateKey: Self.dateKey(for: today))
        overdueTasks = []
        synchronizeCompletionState()
        save()
    }

    func resetRoadmap() {
        activeRoadmap = nil
        roadmapStartDate = nil
        plan = engine.plan(for: now())
        tasks = []
        overdueTasks = []
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
            overdueTasks = []
            completedDateKeys = []
            save()
            return
        }

        completedDateKeys = Set(state.completedDateKeys)
        activeRoadmap = state.activeRoadmap
        roadmapStartDate = state.roadmapStartDate
        plan = currentPlan(for: date)
        var carried = (state.overdueTasks ?? []).filter { !$0.isCompleted }
        if state.dateKey == key {
            tasks = dated(state.tasks, dateKey: key)
            overdueTasks = deduplicated(carried)
        } else {
            carried.append(contentsOf: unfinished(state.tasks, fallbackDateKey: state.dateKey))
            carried.append(contentsOf: missedTasks(after: state.dateKey, before: date))
            overdueTasks = deduplicated(carried)
            tasks = dated(plan.tasks, dateKey: key)
        }
        synchronizeCompletionState()
        save()
    }

    private func missedTasks(after dateKey: String, before today: Date) -> [DailyTask] {
        let calendar = Calendar.autoupdatingCurrent
        guard var cursor = Self.date(from: dateKey, calendar: calendar) else { return [] }
        var result: [DailyTask] = []
        cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? today
        let endKey = Self.dateKey(for: today)

        while Self.dateKey(for: cursor) < endKey {
            let key = Self.dateKey(for: cursor)
            result.append(contentsOf: dated(currentPlan(for: cursor).tasks, dateKey: key))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    private func unfinished(_ source: [DailyTask], fallbackDateKey: String) -> [DailyTask] {
        source.filter { !$0.isCompleted }.map { task in
            var copy = task
            copy.scheduledDateKey = copy.scheduledDateKey ?? fallbackDateKey
            return copy
        }
    }

    private func dated(_ source: [DailyTask], dateKey: String) -> [DailyTask] {
        source.map { task in
            var copy = task
            copy.scheduledDateKey = copy.scheduledDateKey ?? dateKey
            return copy
        }
    }

    private func deduplicated(_ source: [DailyTask]) -> [DailyTask] {
        var seenIDs = Set<UUID>()
        var seenScheduleEntries = Set<String>()
        return source.filter { task in
            let scheduleEntry = [
                task.scheduledDateKey ?? "",
                task.category.rawValue,
                task.title
            ].joined(separator: "|")
            return seenIDs.insert(task.id).inserted
                && seenScheduleEntries.insert(scheduleEntry).inserted
        }
            .sorted { ($0.scheduledDateKey ?? "") < ($1.scheduledDateKey ?? "") }
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

    private func isScheduledWorkday(_ date: Date) -> Bool {
        guard let roadmap = activeRoadmap else { return true }
        let selected = roadmap.selectedWeekdays
            ?? Array(1...max(1, min(7, roadmap.daysPerWeek ?? 5)))
        let appleWeekday = Calendar.autoupdatingCurrent.component(.weekday, from: date)
        let isoWeekday = ((appleWeekday + 5) % 7) + 1
        return selected.contains(isoWeekday)
    }

    private func save() {
        let state = PersistedState(
            dateKey: Self.dateKey(for: now()),
            tasks: tasks,
            completedDateKeys: completedDateKeys.sorted(),
            activeRoadmap: activeRoadmap,
            roadmapStartDate: roadmapStartDate,
            overdueTasks: overdueTasks
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

    private static func date(from key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
