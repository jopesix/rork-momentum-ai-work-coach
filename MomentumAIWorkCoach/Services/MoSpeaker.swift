import AVFoundation

/// Lightweight native TTS so Mo can speak without the ElevenLabs widget.
/// Used for auto-announcements: session opening, check-ins, stuck coaching.
@Observable
@MainActor
class MoSpeaker: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking: Bool = false

    override init() {
        super.init()
        // Allow audio to mix with other apps (e.g. music) and play through speaker
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        // en-GB tends to sound more natural / less robotic on iOS
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .word)
        isSpeaking = false
    }
}
