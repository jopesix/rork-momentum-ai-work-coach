import Foundation

nonisolated struct LastSessionContext: Codable, Sendable {
    var projectName: String?
    var taskSummary: String
    var nextStep: String
    var completedAt: Date
    var blocksCompleted: Int
    var totalDuration: Int
}
