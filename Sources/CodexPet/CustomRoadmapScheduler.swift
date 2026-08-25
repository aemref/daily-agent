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
        let totalDays = max(1, roadmap.durationWeeks * 7)
        let boundedOffset = min(totalDays - 1, offset)
        let weekIndex = min(max(0, boundedOffset / 7), max(0, roadmap.weeks.count - 1))
        let dayInWeek = boundedOffset % 7
        let week = roadmap.weeks[weekIndex]

        let scheduledTasks: [GeneratedTask]
        if dayInWeek < roadmap.daysPerWeek {
            scheduledTasks = week.tasks.enumerated()
                .filter { $0.offset % roadmap.daysPerWeek == dayInWeek }
                .map(\.element)
        } else {
            scheduledTasks = []
        }

        let tasks = scheduledTasks.isEmpty
            ? [DailyTask(
                title: dayInWeek < roadmap.daysPerWeek ? "Haftalık planı gözden geçir" : "Dinlenme ve kısa değerlendirme günü",
                detail: week.outcome,
                category: .review,
                estimatedMinutes: dayInWeek < roadmap.daysPerWeek ? min(30, roadmap.minutesPerDay) : 10
            )]
            : scheduledTasks.map { task in
                DailyTask(
                    title: task.title,
                    detail: task.acceptanceCriteria.isEmpty
                        ? task.detail
                        : task.acceptanceCriteria.joined(separator: " • "),
                    category: category(from: task.category),
                    estimatedMinutes: min(task.estimatedMinutes, roadmap.minutesPerDay)
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
