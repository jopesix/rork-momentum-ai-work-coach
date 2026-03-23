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

    /// Saves the session, updates lastSessionContext, and stamps lastWorkedOn on the project.
    /// Use this instead of saveSession() at the end of every session.
    func recordSessionCompletion(_ session: WorkSession) {
        // Update last session context
        userProfile.lastSessionContext = LastSessionContext(
            projectName: session.projectName,
            taskSummary: session.whatWasDone.isEmpty ? session.startingTask : session.whatWasDone,
            nextStep: session.nextStep,
            completedAt: session.date,
            blocksCompleted: session.blocksCompleted,
            totalDuration: session.totalDuration
        )
        // Stamp lastWorkedOn on the matching project
        if let name = session.projectName,
           let idx = userProfile.projects.firstIndex(where: { $0.name == name }) {
            userProfile.projects[idx].lastWorkedOn = Date()
        }
        saveProfile()
        saveSession(session)
    }

    var activeProjects: [Project] {
        userProfile.projects.filter { $0.isActive }
    }

    // MARK: - Tasks

    var pendingTasks: [MoTask] {
        userProfile.tasks.filter { $0.status == .pending }
    }

    var completedTasks: [MoTask] {
        userProfile.tasks
            .filter { $0.status == .done }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    var allProjectTags: [String] {
        Array(Set(userProfile.tasks.compactMap(\.projectTag))).sorted()
    }

    func addTask(_ task: MoTask) {
        userProfile.tasks.append(task)
        saveProfile()
    }

    func completeTask(id: String) {
        guard let idx = userProfile.tasks.firstIndex(where: { $0.id == id }) else { return }
        userProfile.tasks[idx].status = .done
        userProfile.tasks[idx].completedAt = Date()
        saveProfile()
    }

    func deleteTask(id: String) {
        userProfile.tasks.removeAll { $0.id == id }
        saveProfile()
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
