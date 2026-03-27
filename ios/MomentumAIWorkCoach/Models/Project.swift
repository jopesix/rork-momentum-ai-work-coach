import Foundation

nonisolated struct Project: Codable, Identifiable, Sendable {
    var id: String = UUID().uuidString
    var name: String
    var description: String = ""
    var isActive: Bool = true
    var lastWorkedOn: Date? = nil
    var createdAt: Date = Date()
}
