import Foundation

enum SessionPhaseContext: String {
    case brainDump    = "brain_dump"
    case activation   = "activation"
    case working      = "working"
    case onBreak      = "on_break"
    case ended        = "ended"
    case celebration  = "celebration"
}

enum StuckType: String, Codable, CaseIterable {
    case overwhelm    = "overwhelm"
    case distraction  = "distraction"
    case unclear      = "unclear"
    case lowEnergy    = "low_energy"

    var displayName: String {
        switch self {
        case .overwhelm:   return "Overwhelmed"
        case .distraction: return "Distracted"
        case .unclear:     return "Not sure what to do next"
        case .lowEnergy:   return "Low energy"
        }
    }
}

struct StuckContext {
    let minutesIntoSession: Int
    let currentTask: String
    let stuckType: StuckType
}

struct MoContextBuilder {

    static func build(
        profile: UserProfile,
        session: WorkSession? = nil,
        phase: SessionPhaseContext,
        elapsedMinutes: Int = 0,
        checkInNumber: Int = 0,
        stuckContext: StuckContext? = nil,
        totalSessions: Int = 0,
        totalHours: Double = 0
    ) -> String {
        var dict: [String: Any] = [:]

        // User profile
        let cp = profile.coachingProfile
        var userDict: [String: Any] = [
            "coachingStyle": cp.coachingStyle.rawValue
        ]
        if !cp.name.isEmpty         { userDict["name"] = cp.name }
        if !cp.patterns.isEmpty     { userDict["patterns"] = cp.patterns }
        if !cp.notes.isEmpty        { userDict["notes"] = cp.notes }
        dict["user"] = userDict

        // Session
        if let session = session {
            var sessionDict: [String: Any] = ["phase": phase.rawValue]
            if !session.brainDump.isEmpty      { sessionDict["brainDump"] = session.brainDump }
            if !session.startingTask.isEmpty   { sessionDict["startingTask"] = session.startingTask }
            if !session.suggestedMilestones.isEmpty {
                sessionDict["milestones"] = session.suggestedMilestones
            }
            if elapsedMinutes > 0  { sessionDict["elapsedMinutes"] = elapsedMinutes }
            if checkInNumber > 0   { sessionDict["checkInNumber"] = checkInNumber }
            if !session.moOpeningMessage.isEmpty {
                sessionDict["moOpeningMessage"] = session.moOpeningMessage
            }
            dict["session"] = sessionDict
        } else {
            dict["session"] = ["phase": phase.rawValue]
        }

        // Last session carry-forward
        if let last = profile.lastSessionContext {
            var lastDict: [String: Any] = [
                "taskSummary": last.taskSummary,
                "nextStep": last.nextStep,
                "blocksCompleted": last.blocksCompleted
            ]
            if let proj = last.projectName { lastDict["projectName"] = proj }
            let formatter = ISO8601DateFormatter()
            lastDict["completedAt"] = formatter.string(from: last.completedAt)
            dict["lastSession"] = lastDict
        }

        // Active projects (max 10, keep it compact)
        let projects = profile.projects.filter { $0.isActive }.prefix(10)
        if !projects.isEmpty {
            dict["projects"] = projects.map { p -> [String: Any] in
                var pd: [String: Any] = ["name": p.name]
                if !p.description.isEmpty { pd["description"] = p.description }
                if let d = p.lastWorkedOn {
                    pd["lastWorkedOn"] = ISO8601DateFormatter().string(from: d)
                }
                return pd
            }
        }

        // Stuck context — only included when user taps "I'm Stuck"
        if let stuck = stuckContext {
            dict["stuck"] = [
                "isStuck": true,
                "minutesIntoSession": stuck.minutesIntoSession,
                "currentTask": stuck.currentTask,
                "stuckType": stuck.stuckType.rawValue
            ]
        }

        // App stats
        dict["appStats"] = [
            "totalSessions": totalSessions,
            "totalHours": String(format: "%.1f", totalHours)
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
