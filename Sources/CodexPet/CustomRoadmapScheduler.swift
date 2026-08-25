import Foundation

struct CustomRoadmapScheduler: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func plan(for date: Date, roadmap: GeneratedRoadmap, startDate: Date) -> RoadmapDay {
        let start = calendar.startOfDay(for: startDate)
        let current = calendar.startOfDay(for: date)
        let offset = max(0, calendar.dateComponents([.day], from: start, to: current).day ?? 0)
        let totalDays = 365
        let boundedOffset = min(totalDays - 1, offset)
        let weekIndex = min(max(0, boundedOffset / 7), max(0, roadmap.weeks.count - 1))
        let week = roadmap.weeks[weekIndex]
        let selectedWeekdays = normalizedWeekdays(for: roadmap)
        let currentWeekday = isoWeekday(for: current)

        let scheduledTasks: [GeneratedTask]
        if let selectedDayIndex = selectedWeekdays.firstIndex(of: currentWeekday) {
            scheduledTasks = week.tasks.enumerated()
                .filter { $0.offset % selectedWeekdays.count == selectedDayIndex }
                .map(\.element)
        } else {
            scheduledTasks = []
        }

        let isWorkday = selectedWeekdays.contains(currentWeekday)
        let tasks = scheduledTasks.isEmpty && isWorkday
            ? [DailyTask(
                title: "Haftalık planı gözden geçir",
                detail: week.outcome,
                category: .review,
                estimatedMinutes: 0,
                checklist: [
                    "Haftanın hedefini ve mevcut ilerlemeyi karşılaştır.",
                    "Eksik veya engellenen işleri nedenleriyle birlikte kaydet.",
                    "Sonraki çalışma günü için küçük ve doğrulanabilir bir adım belirle."
                ],
                completionCriteria: week.outcome
            )]
            : scheduledTasks.map { task in
                DailyTask(
                    title: task.title,
                    detail: task.detail,
                    category: category(from: task.category),
                    estimatedMinutes: 0,
                    checklist: task.acceptanceCriteria.isEmpty ? nil : task.acceptanceCriteria,
                    completionCriteria: task.acceptanceCriteria.isEmpty
                        ? nil
                        : task.acceptanceCriteria.joined(separator: " • ")
                )
            }

        return RoadmapDay(
            dayNumber: boundedOffset + 1,
            totalDays: totalDays,
            monthNumber: min(roadmap.durationWeeks, weekIndex + 1),
            milestone: week.milestone,
            focus: week.theme,
            repository: roadmap.title,
            tasks: tasks
        )
    }

    private func normalizedWeekdays(for roadmap: GeneratedRoadmap) -> [Int] {
        let explicit = roadmap.selectedWeekdays ?? []
        let valid = Array(Set(explicit.filter { (1...7).contains($0) })).sorted()
        if !valid.isEmpty { return valid }
        return Array(1...max(1, min(7, roadmap.daysPerWeek ?? 5)))
    }

    private func isoWeekday(for date: Date) -> Int {
        let appleWeekday = calendar.component(.weekday, from: date)
        return ((appleWeekday + 5) % 7) + 1
    }

    private func category(from value: String) -> TaskCategory {
        switch value.lowercased() {
        case "learn": .learn
        case "build", "project": .build
        case "review": .review
        case "github": .github
        case "aws": .aws
        default: .test
        }
    }
}
