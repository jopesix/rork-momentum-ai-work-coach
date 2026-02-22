import Foundation

nonisolated struct UserProfile: Codable, Sendable {
    var defaultBlockLength: Int = 25
    var defaultBreakLength: Int = 5
    var notificationsEnabled: Bool = true
}
