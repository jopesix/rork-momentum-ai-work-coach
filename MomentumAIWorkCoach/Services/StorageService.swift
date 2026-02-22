import Foundation

@Observable
@MainActor
class StorageService {
    private let profileKey = "momentum_user_profile"
    private let sessionsKey = "momentum_sessions"

    var userProfile: UserProfile = UserProfile()
    var sessions: [WorkSession] = []

    init() {
        loadProfile()
        loadSessions()
    }

    func saveProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else { return }
        userProfile = profile
    }

    func saveSession(_ session: WorkSession) {
        sessions.insert(session, at: 0)
        saveSessions()
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let loaded = try? JSONDecoder().decode([WorkSession].self, from: data) else { return }
        sessions = loaded
    }

    var totalSessionCount: Int {
        sessions.count
    }

    var totalCompletedItems: Int {
        sessions.reduce(0) { total, session in
            total + session.milestones.filter(\.isCompleted).count + (session.whatWasDone.isEmpty ? 0 : 1)
        }
    }

    var totalHours: Double {
        Double(sessions.reduce(0) { $0 + $1.totalDuration }) / 60.0
    }
}
