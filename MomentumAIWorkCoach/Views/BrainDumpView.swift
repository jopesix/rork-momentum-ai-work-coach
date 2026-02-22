import SwiftUI

struct BrainDumpView: View {
    let onDone: (String) -> Void

    @State private var inputMode: InputMode = .speak
    @State private var typedText: String = ""
    @State private var speechService = SpeechService()
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("What's on your mind today?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Say everything. Mo will sort it out.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 24)

                modeToggle
                    .padding(.top, 20)

                Spacer()
                    .frame(height: 24)

                Group {
                    switch inputMode {
                    case .speak:
                        voiceMode
                    case .type:
                        typeMode
                    }
                }
                .animation(.snappy, value: inputMode)

                Spacer()

                Button {
                    let dump = inputMode == .speak ? speechService.transcript : typedText
                    onDone(dump)
                } label: {
                    Text("Done — what should I start?")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(hasDump ? Theme.primaryTeal : Theme.primaryTeal.opacity(0.35))
                        .clipShape(.rect(cornerRadius: 16))
                }
                .disabled(!hasDump)
                .sensoryFeedback(.impact(weight: .medium), trigger: hasDump)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            speechService.requestAuthorization()
        }
        .onDisappear {
            speechService.stopRecording()
        }
    }

    private var hasDump: Bool {
        let text = inputMode == .speak ? speechService.transcript : typedText
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton("Speak", icon: "mic.fill", mode: .speak)
            modeButton("Type", icon: "pencil", mode: .type)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .padding(.horizontal, 80)
    }

    private func modeButton(_ label: String, icon: String, mode: InputMode) -> some View {
        let isSelected = inputMode == mode
        return Button {
            if speechService.isRecording { speechService.stopRecording() }
            inputMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.primaryTeal : .clear)
            .clipShape(Capsule())
        }
    }

    private var voiceMode: some View {
        VStack(spacing: 20) {
            Button {
                if speechService.isRecording {
                    speechService.stopRecording()
                } else {
                    speechService.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.primaryTeal.opacity(0.08))
                        .frame(width: 180, height: 180)
                        .scaleEffect(speechService.isRecording ? pulseScale : 1.0)

                    Circle()
                        .fill(Theme.primaryTeal.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(speechService.isRecording ? pulseScale * 0.95 : 1.0)

                    Circle()
                        .fill(speechService.isRecording ? Theme.primaryTeal : Theme.primaryTeal.opacity(0.8))
                        .frame(width: 100, height: 100)

                    Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: speechService.isRecording)
            .onChange(of: speechService.isRecording) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulseScale = 1.15
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        pulseScale = 1.0
                    }
                }
            }

            Text(speechService.isRecording ? "Listening..." : "Tap to speak")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(speechService.isRecording ? Theme.primaryTeal : Theme.textSecondary)

            if !speechService.transcript.isEmpty {
                ScrollView {
                    Text(speechService.transcript)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 160)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 24)
            }
        }
    }

    private var typeMode: some View {
        VStack(spacing: 0) {
            TextEditor(text: $typedText)
                .font(.system(size: 16))
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 14))
                .overlay(alignment: .topLeading) {
                    if typedText.isEmpty {
                        Text("Write everything you want to work on.\nDon't organise it. Just get it out.")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(.placeholderText))
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 24)
        }
    }
}

nonisolated enum InputMode: Sendable {
    case speak, type
}
