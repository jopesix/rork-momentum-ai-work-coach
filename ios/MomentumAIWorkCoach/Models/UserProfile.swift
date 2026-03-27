import Foundation

nonisolated struct UserProfile: Codable, Sendable {
    var defaultBlockLength: Int = 25
    var defaultBreakLength: Int = 5
    var notificationsEnabled: Bool = true

    // Coaching context — all have defaults so existing saved profiles decode cleanly
    var coachingProfile: CoachingProfile = CoachingProfile()
    var projects: [Project] = []
    var lastSessionContext: LastSessionContext? = nil
    var tasks: [MoTask] = []
}
