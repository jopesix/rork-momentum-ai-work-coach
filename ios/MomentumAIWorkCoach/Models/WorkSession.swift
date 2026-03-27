import Foundation

nonisolated struct WorkSession: Codable, Identifiable, Sendable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var totalDuration: Int = 0
    var blocksCompleted: Int = 0
    var whatWasDone: String = ""
    var nextStep: String = ""
    var milestones: [Milestone] = []
    var brainDump: String = ""
    var projectName: String? = nil

    // Populated by ClaudeService at activation
    var startingTask: String = ""
    var suggestedMilestones: [String] = []
    var moOpeningMessage: String = ""
}

nonisolated struct Milestone: Codable, Identifiable, Sendable {
    var id: String = UUID().uuidString
    var title: String
    var isCompleted: Bool = false
}
