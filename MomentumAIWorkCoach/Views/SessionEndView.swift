import SwiftUI

struct SessionEndView: View {
    let totalDuration: Int
    let blocksCompleted: Int
    let completedMilestones: [Milestone]
    let onSave: (String, String) -> Void

    @State private var inputMode: InputMode = .type
    @State private var whatWasDone: String = ""
    @State private var nextStep: String = ""
    @State private var appeared: Bool = false
    @State private var speechService = SpeechService()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Theme.primaryLight)
                                .frame(width: 80, height: 80)
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Theme.primaryTeal)
                        }
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.7)

                        Text("You showed up.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)

                        Text("Tell Mo what you got done.")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textSecondary)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                    }
                    .padding(.top, 48)

                    VStack(alignment: .leading, spacing: 20) {
                        modeToggle

                        Group {
                            if inputMode == .speak {
                                voiceInput
                            } else {
                                textInput
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR NEXT STEP")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .tracking(0.5)
                            TextField("The one specific thing to do next time.", text: $nextStep)
                                .font(.system(size: 15))
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(.rect(cornerRadius: 12))
                        }

                        HStack(spacing: 16) {
                            Label("\(totalDuration) min", systemImage: "clock")
                            Label("\(blocksCompleted) block\(blocksCompleted == 1 ? "" : "s")", systemImage: "square.stack")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(20)
                    .background(Theme.primaryLight)
                    .clipShape(.rect(cornerRadius: 14))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button {
                    let done: String
                    if inputMode == .speak && !speechService.transcript.isEmpty {
                        done = speechService.transcript
                    } else if !whatWasDone.isEmpty {
                        done = whatWasDone
                    } else {
                        done = completedMilestones.map(\.title).joined(separator: ", ")
                    }
                    onSave(done, nextStep)
                } label: {
                    Text("Save to Wins")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.primaryTeal)
                        .clipShape(.rect(cornerRadius: 16))
                }
                .sensoryFeedback(.success, trigger: appeared)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.bar)
            }
        }
        .onAppear {
            speechService.requestAuthorization()
            if !completedMilestones.isEmpty {
                whatWasDone = completedMilestones.map(\.title).joined(separator: "\n")
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
        .onDisappear {
            speechService.stopRecording()
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton("Speak", icon: "mic.fill", mode: .speak)
            modeButton("Type", icon: "pencil", mode: .type)
        }
        .background(Color(.tertiarySystemFill))
        .clipShape(Capsule())
    }

    private func modeButton(_ label: String, icon: String, mode: InputMode) -> some View {
        let isSelected = inputMode == mode
        return Button {
            if speechService.isRecording { speechService.stopRecording() }
            inputMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.primaryTeal : .clear)
            .clipShape(Capsule())
        }
    }

    private var voiceInput: some View {
        VStack(spacing: 12) {
            Button {
                if speechService.isRecording {
                    speechService.stopRecording()
                } else {
                    speechService.startRecording()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24))
                    Text(speechService.isRecording ? "Stop recording" : "Tap to speak your summary")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(speechService.isRecording ? .red : Theme.primaryTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 12))
            }

            if !speechService.transcript.isEmpty {
                Text(speechService.transcript)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 10))
            }
        }
    }

    private var textInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT DID YOU GET DONE?")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.5)
            TextEditor(text: $whatWasDone)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if whatWasDone.isEmpty {
                        Text("Even small things count. Write it out.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.placeholderText))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}
