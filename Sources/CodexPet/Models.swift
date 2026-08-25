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

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        category: TaskCategory,
        estimatedMinutes: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.estimatedMinutes = estimatedMinutes
        self.isCompleted = isCompleted
    }
}

struct RoadmapDay: Equatable, Sendable {
    let dayNumber: Int
    let monthNumber: Int
    let milestone: String
    let focus: String
    let repository: String
    let tasks: [DailyTask]
}

struct PersistedState: Codable, Sendable {
    var dateKey: String
    var tasks: [DailyTask]
    var completedDateKeys: [String]

    static let empty = PersistedState(dateKey: "", tasks: [], completedDateKeys: [])
}
