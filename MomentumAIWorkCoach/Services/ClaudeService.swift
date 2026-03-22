import Foundation

struct ActivationResult {
    let startingTask: String
    let suggestedMilestones: [String]
    let moOpeningMessage: String
}

actor ClaudeService {

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private var apiKey: String {
        // Load from Info.plist key CLAUDE_API_KEY
        let fromPlist = Bundle.main.object(forInfoDictionaryKey: "ClaudeApiKey") as? String ?? ""
        if !fromPlist.isEmpty { return fromPlist }
        let fromEnv = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
        return fromEnv
    }

    func getActivationPlan(brainDump: String, profile: UserProfile, totalSessions: Int, totalHours: Double) async throws -> ActivationResult {
        let systemPrompt = buildSystemPrompt(profile: profile, totalSessions: totalSessions, totalHours: totalHours)

        let body: [String: Any] = [
            "model": "claude-opus-4-5",
            "max_tokens": 512,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "Brain dump: \"\(brainDump)\"\n\nWhat should I start with?"]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClaudeError.badResponse
        }

        return try parseResponse(data: data, brainDump: brainDump)
    }

    // MARK: - Private

    private func buildSystemPrompt(profile: UserProfile, totalSessions: Int, totalHours: Double) -> String {
        let cp = profile.coachingProfile
        let name = cp.name.isEmpty ? "the user" : cp.name
        let style = cp.coachingStyle.rawValue

        var prompt = """
        You are Mo, an AI productivity coach for people with ADHD, overwhelm, and executive dysfunction.
        Your job: read a brain dump and help \(name) start their work session with clarity and confidence.
        Coaching style: \(style). Be warm, brief, human. Never shame, never judge.

        User profile:
        - Name: \(name)
        - Coaching style: \(style)
        """

        if !cp.patterns.isEmpty {
            prompt += "\n- Known patterns: \(cp.patterns)"
        }
        if !cp.notes.isEmpty {
            prompt += "\n- Notes: \(cp.notes)"
        }

        if let last = profile.lastSessionContext {
            prompt += "\n\nLast session:\n- Worked on: \(last.taskSummary)"
            if !last.nextStep.isEmpty {
                prompt += "\n- Their next step was: \(last.nextStep)"
            }
        }

        let activeProjects = profile.projects.filter { $0.isActive }
        if !activeProjects.isEmpty {
            let names = activeProjects.map { $0.name }.joined(separator: ", ")
            prompt += "\n\nActive projects: \(names)"
        }

        prompt += "\n\nStats: \(totalSessions) sessions completed, \(String(format: "%.1f", totalHours)) total hours."

        prompt += """


        Return ONLY valid JSON in this exact shape, no markdown, no commentary:
        {
          "startingTask": "one clear, specific, concrete task to begin with",
          "suggestedMilestones": ["step 1", "step 2", "step 3"],
          "moOpeningMessage": "a warm 1-2 sentence spoken opener Mo will say aloud"
        }

        Rules:
        - startingTask: concrete, achievable in one focus block, verb-first
        - suggestedMilestones: 2-4 items, verb-first, short (max 8 words each)
        - moOpeningMessage: conversational, matches \(style) style, reference last session if relevant
        - No markdown, no extra keys, no text outside the JSON object
        """

        return prompt
    }

    private func parseResponse(data: Data, brainDump: String) throws -> ActivationResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw ClaudeError.parseError
        }

        // Strip any accidental markdown fences
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw ClaudeError.parseError
        }

        let startingTask = result["startingTask"] as? String ?? fallbackTask(from: brainDump)
        let milestones = result["suggestedMilestones"] as? [String] ?? []
        let opening = result["moOpeningMessage"] as? String ?? "Let's get started. You've got this."

        return ActivationResult(
            startingTask: startingTask,
            suggestedMilestones: milestones,
            moOpeningMessage: opening
        )
    }

    private func fallbackTask(from brainDump: String) -> String {
        let lines = brainDump.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return String((lines.first ?? brainDump).prefix(100))
    }
}

enum ClaudeError: Error {
    case badResponse
    case parseError
    case missingApiKey
}
