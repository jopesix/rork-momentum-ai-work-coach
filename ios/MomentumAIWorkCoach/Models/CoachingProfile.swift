import Foundation

enum CoachingStyle: String, Codable, CaseIterable, Sendable {
    case supportive   = "supportive"
    case encouraging  = "encouraging"
    case direct       = "direct"
    case analytical   = "analytical"

    var displayName: String {
        switch self {
        case .supportive:  return "Supportive"
        case .encouraging: return "Encouraging"
        case .direct:      return "Direct"
        case .analytical:  return "Analytical"
        }
    }

    var description: String {
        switch self {
        case .supportive:  return "Gentle, calm, no pressure"
        case .encouraging: return "Warm cheerleader energy"
        case .direct:      return "Cut to the chase, no fluff"
        case .analytical:  return "Break it down logically"
        }
    }
}

nonisolated struct CoachingProfile: Codable, Sendable {
    var name: String = ""
    var coachingStyle: CoachingStyle = .encouraging
    var patterns: String = ""
    var notes: String = ""
}
