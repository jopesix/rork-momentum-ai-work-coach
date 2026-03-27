import SwiftUI

struct SessionEndView: View {
    let totalDuration: Int
    let blocksCompleted: Int
    let completedMilestones: [Milestone]
    let session: WorkSession
    let onSave: (String, String) -> Void
    let onContinue: () -> Void          // ← back to session

    @Environment(StorageService.self) private var storage

    @State private var inputMode: InputMode = .type
    @State private var whatWasDone: String = ""
    @State private var nextStep: String = ""
    @State private var appeared: Bool = false
    @State private var speechService = SpeechService()

    // Celebration
    @State private var showCelebration: Bool = false
    @State private var pendingDone: String = ""
    @State private var pendingNext: String = ""

    var body: some View {
        ZStack {
            Theme.backgroundMain.ignoresSafeArea()

            if showCelebration {
                celebrationView.transition(.opacity)
            } else {
                mainContent
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
        .onDisappear { speechService.stopRecording() }
        .animation(.easeInOut(duration: 0.4), value: showCelebration)
    }

    // MARK: - Main content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Theme.primaryLight).frame(width: 80, height: 80)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 34)).foregroundStyle(Theme.primaryTeal)
                    }
                    .opacity(appeared ? 1 : 0).scaleEffect(appeared ? 1 : 0.7)

                    Text("You showed up.")
                        .font(.system(size: 28, weight: .bold)).foregroundStyle(Theme.textPrimary)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 12)

                    Text("Tell Mo what you got done.")
                        .font(.system(size: 16)).foregroundStyle(Theme.textSecondary)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 12)
                }
                .padding(.top, 40)

                // Stats row
                HStack(spacing: 20) {
                    statPill("\(totalDuration) min", icon: "clock")
                    statPill("\(blocksCompleted) block\(blocksCompleted == 1 ? "" : "s")", icon: "square.stack")
                }
                .opacity(appeared ? 1 : 0)

                // Form card
                VStack(alignment: .leading, spacing: 16) {
                    modeToggle

                    Group {
                        if inputMode == .speak { voiceInput }
                        else { textInput }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR NEXT STEP")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(0.5)
                        TextField("The one specific thing to do next time.", text: $nextStep)
                            .font(.system(size: 15)).padding(14)
                            .background(Theme.inputBackground)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(16)
                .background(Theme.cardBackground)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)

                // Keep going escape hatch
                Button {
                    onContinue()
                } label: {
                    Text("Actually, keep going →")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .opacity(appeared ? 1 : 0)

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
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
                pendingDone = done
                pendingNext = nextStep
                withAnimation { showCelebration = true }
            } label: {
                Text("Save to Wins")
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Theme.primaryTeal).clipShape(.rect(cornerRadius: 16))
            }
            .sensoryFeedback(.success, trigger: appeared)
            .padding(.horizontal, 20).padding(.vertical, 12).background(.bar)
        }
    }

    // MARK: - Celebration

    private var celebrationView: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Theme.primaryLight).frame(width: 100, height: 100)
                    Text("🎉").font(.system(size: 48))
                }
                Text("Look at that.")
                    .font(.system(size: 32, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text("You actually did it.")
                    .font(.system(size: 18)).foregroundStyle(Theme.textSecondary)
            }

            if !Constants.elevenlabsAgentId.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        MoPresenceIndicator()
                        Text("MO IS CELEBRATING WITH YOU")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary).tracking(0.8)
                    }
                    MoWidgetView(agentId: Constants.elevenlabsAgentId, context: buildCelebrationContext())
                        .frame(height: 160).clipShape(.rect(cornerRadius: 12))
                }
                .padding(16).background(Theme.cardBackground)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
                .padding(.horizontal, 20)
            }

            Spacer()

            Button { onSave(pendingDone, pendingNext) } label: {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Theme.primaryTeal).clipShape(.rect(cornerRadius: 16))
            }
            .padding(.horizontal, 20).padding(.bottom, 32)
        }
    }

    // MARK: - Helpers

    private func statPill(_ label: String, icon: String) -> some View {
        Label(label, systemImage: icon)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Theme.cardBackground)
            .clipShape(Capsule())
    }

    private func buildCelebrationContext() -> String {
        var s = session
        s.whatWasDone = pendingDone
        s.nextStep = pendingNext
        s.totalDuration = totalDuration
        s.blocksCompleted = blocksCompleted
        return MoContextBuilder.build(
            profile: storage.userProfile,
            session: s,
            phase: .celebration,
            totalSessions: storage.totalSessionCount,
            totalHours: storage.totalHours
        )
    }

    // MARK: - Input controls

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton("Speak", icon: "mic.fill", mode: .speak)
            modeButton("Type", icon: "pencil", mode: .type)
        }
        .background(Theme.inputBackground).clipShape(Capsule())
    }

    private func modeButton(_ label: String, icon: String, mode: InputMode) -> some View {
        let isSelected = inputMode == mode
        return Button {
            if speechService.isRecording { speechService.stopRecording() }
            inputMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .medium))
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(isSelected ? Theme.primaryTeal : .clear).clipShape(Capsule())
        }
    }

    private var voiceInput: some View {
        VStack(spacing: 12) {
            Button {
                if speechService.isRecording { speechService.stopRecording() }
                else { speechService.startRecording() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24))
                    Text(speechService.isRecording ? "Stop recording" : "Tap to speak your summary")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(speechService.isRecording ? .red : Theme.primaryTeal)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Theme.inputBackground).clipShape(.rect(cornerRadius: 12))
            }
            if !speechService.transcript.isEmpty {
                Text(speechService.transcript)
                    .font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .background(Theme.inputBackground).clipShape(.rect(cornerRadius: 10))
            }
        }
    }

    private var textInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT DID YOU GET DONE?")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary).tracking(0.5)
            TextEditor(text: $whatWasDone)
                .font(.system(size: 15)).scrollContentBackground(.hidden)
                .frame(minHeight: 80).padding(10)
                .background(Theme.inputBackground).clipShape(.rect(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if whatWasDone.isEmpty {
                        Text("Even small things count. Write it out.")
                            .font(.system(size: 15)).foregroundStyle(Color(.placeholderText))
                            .padding(.horizontal, 14).padding(.vertical, 18).allowsHitTesting(false)
                    }
                }
        }
    }
}
