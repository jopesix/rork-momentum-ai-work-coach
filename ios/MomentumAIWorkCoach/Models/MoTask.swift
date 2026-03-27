import Foundation

nonisolated enum TaskStatus: String, Codable, Sendable {
    case pending, done
}

nonisolated struct MoTask: Codable, Identifiable, Sendable {
    var id: String = UUID().uuidString
    var title: String
    var notes: String = ""
    var projectTag: String? = nil
    var status: TaskStatus = .pending
    var createdAt: Date = Date()
    var completedAt: Date? = nil
}
