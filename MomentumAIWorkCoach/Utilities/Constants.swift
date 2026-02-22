import Foundation

enum Constants {
    static let elevenlabsAgentId: String = {
        let fromPlist = Bundle.main.object(forInfoDictionaryKey: "ElevenLabsAgentId") as? String ?? ""
        if !fromPlist.isEmpty { return fromPlist }
        let fromEnv = ProcessInfo.processInfo.environment["EXPO_PUBLIC_ELEVENLABS_AGENT_ID"] ?? ""
        if !fromEnv.isEmpty { return fromEnv }
        return ""
    }()
}
