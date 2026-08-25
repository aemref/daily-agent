import Foundation

enum TaskCategory: String, Codable, CaseIterable, Sendable {
    case learn = "Öğren"
    case build = "Geliştir"
    case test = "Test / Eval"
    case aws = "AWS"
    case github = "GitHub"
    case review = "Dokümantasyon"

    var symbol: String {
        switch self {
        case .learn: "book.closed.fill"
        case .build: "hammer.fill"
        case .test: "checkmark.seal.fill"
        case .aws: "cloud.fill"
        case .github: "arrow.triangle.branch"
        case .review: "doc.text.fill"
        }
    }
}

struct DailyTask: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var detail: String
    var category: TaskCategory
    var estimatedMinutes: Int
    var isCompleted: Bool
    var scheduledDateKey: String?
    var checklist: [String]?
    var completionCriteria: String?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        category: TaskCategory,
        estimatedMinutes: Int,
        isCompleted: Bool = false,
        scheduledDateKey: String? = nil,
        checklist: [String]? = nil,
        completionCriteria: String? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.estimatedMinutes = estimatedMinutes
        self.isCompleted = isCompleted
        self.scheduledDateKey = scheduledDateKey
        self.checklist = checklist
        self.completionCriteria = completionCriteria
    }
}

struct RoadmapDay: Equatable, Sendable {
    let dayNumber: Int
    let totalDays: Int
    let monthNumber: Int
    let milestone: String
    let focus: String
    let repository: String
    let tasks: [DailyTask]
}

struct GeneratedRoadmap: Codable, Equatable, Sendable {
    var title: String
    var summary: String
    var durationWeeks: Int
    var daysPerWeek: Int?
    var minutesPerDay: Int?
    var selectedWeekdays: [Int]?
    var weeks: [GeneratedWeek]

    var taskCount: Int {
        weeks.reduce(0) { $0 + $1.tasks.count }
    }
}

struct GeneratedWeek: Codable, Equatable, Sendable {
    var weekNumber: Int
    var milestone: String
    var theme: String
    var outcome: String
    var tasks: [GeneratedTask]
}

struct GeneratedTask: Codable, Equatable, Sendable {
    var title: String
    var detail: String
    var category: String
    var estimatedMinutes: Int?
    var acceptanceCriteria: [String]
}

struct SchedulePreferences: Equatable, Sendable {
    var selectedWeekdays: Set<Int> = [1, 2, 3, 4, 5]

    let durationWeeks = 52

    var daysPerWeek: Int { selectedWeekdays.count }
}

struct PersistedState: Codable, Sendable {
    var dateKey: String
    var tasks: [DailyTask]
    var completedDateKeys: [String]
    var activeRoadmap: GeneratedRoadmap?
    var roadmapStartDate: Date?
    var overdueTasks: [DailyTask]?

    static let empty = PersistedState(
        dateKey: "",
        tasks: [],
        completedDateKeys: [],
        activeRoadmap: nil,
        roadmapStartDate: nil,
        overdueTasks: []
    )
}
