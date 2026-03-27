import Foundation

enum Constants {
    static let elevenlabsAgentId: String = {
        let fromPlist = Bundle.main.object(forInfoDictionaryKey: "ElevenLabsAgentId") as? String ?? ""
        if !fromPlist.isEmpty { return fromPlist }
        let fromEnv = ProcessInfo.processInfo.environment["EXPO_PUBLIC_ELEVENLABS_AGENT_ID"] ?? ""
        if !fromEnv.isEmpty { return fromEnv }
        return ""
    }()

    /// Add CLAUDE_API_KEY to Info.plist (never commit the value to source control)
    static let claudeApiKey: String = {
        let fromPlist = Bundle.main.object(forInfoDictionaryKey: "ClaudeApiKey") as? String ?? ""
        if !fromPlist.isEmpty { return fromPlist }
        return ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
    }()
}
