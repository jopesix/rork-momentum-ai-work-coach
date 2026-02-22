import Foundation
import Speech
import AVFoundation

@Observable
@MainActor
class SpeechService {
    var isRecording: Bool = false
    var transcript: String = ""
    var isAuthorized: Bool = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.isAuthorized = status == .authorized
            }
        }
    }

    func startRecording() {
        guard isAuthorized, let speechRecognizer, speechRecognizer.isAvailable else { return }

        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        audioEngine = AVAudioEngine()
        guard let audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopEngine()
                }
            }
        }

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            stopEngine()
        }
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        stopEngine()
    }

    private func stopEngine() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    func reset() {
        stopRecording()
        transcript = ""
    }
}
