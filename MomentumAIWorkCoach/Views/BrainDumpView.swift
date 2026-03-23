import SwiftUI

struct BrainDumpView: View {
    let carryForwardContext: LastSessionContext?
    let activeProjects: [Project]
    let selectedProjectName: String?
    /// dump text, selected project name
    let onDone: (String, String?) -> Void

    @State private var inputMode: InputMode = .speak
    @State private var typedText: String = ""
    @State private var speechService = SpeechService()
    @State private var pulseScale: CGFloat = 1.0
    @State private var chosenProjectName: String? = nil
    @State private var showCarryForward: Bool = true

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

                // Carry-forward banner
                if let last = carryForwardContext, showCarryForward {
                    carryForwardBanner(last: last)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Project selector
                if !activeProjects.isEmpty {
                    projectSelector
                        .padding(.top, 12)
                }

                modeToggle.padding(.top, 20)

                Spacer().frame(height: 24)

                Group {
                    switch inputMode {
                    case .speak: voiceMode
                    case .type:  typeMode
                    }
                }
                .animation(.snappy, value: inputMode)

                Spacer()

                Button {
                    let dump = inputMode == .speak ? speechService.transcript : typedText
                    onDone(dump, chosenProjectName)
                } label: {
                    Text("Done — what should I start?")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
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
            chosenProjectName = selectedProjectName
        }
        .onDisappear { speechService.stopRecording() }
        .animation(.spring(response: 0.4), value: showCarryForward)
    }

    // MARK: - Carry-forward banner

    private func carryForwardBanner(last: LastSessionContext) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 14))
                .foregroundStyle(Theme.primaryTeal)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Last time: \(last.taskSummary)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                if !last.nextStep.isEmpty {
                    Text("Next step: \(last.nextStep)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button { withAnimation { showCarryForward = false } } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(12)
        .background(Theme.primaryLight)
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: - Project selector

    private var projectSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                // "None" chip
                projectChip(name: nil)
                ForEach(activeProjects) { project in
                    projectChip(name: project.name)
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func projectChip(name: String?) -> some View {
        let isSelected = chosenProjectName == name
        return Button {
            chosenProjectName = isSelected ? nil : name
        } label: {
            Text(name ?? "No project")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Theme.primaryTeal : Theme.inputBackground)
                .clipShape(Capsule())
        }
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton("Speak", icon: "mic.fill", mode: .speak)
            modeButton("Type", icon: "pencil", mode: .type)
        }
        .background(Theme.inputBackground)
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
                Image(systemName: icon).font(.system(size: 13, weight: .medium))
                Text(label).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(isSelected ? Theme.primaryTeal : .clear)
            .clipShape(Capsule())
        }
    }

    // MARK: - Voice mode

    private var voiceMode: some View {
        VStack(spacing: 20) {
            Button {
                if speechService.isRecording { speechService.stopRecording() }
                else { speechService.startRecording() }
            } label: {
                ZStack {
                    Circle().fill(Theme.primaryTeal.opacity(0.08)).frame(width: 180, height: 180)
                        .scaleEffect(speechService.isRecording ? pulseScale : 1.0)
                    Circle().fill(Theme.primaryTeal.opacity(0.15)).frame(width: 140, height: 140)
                        .scaleEffect(speechService.isRecording ? pulseScale * 0.95 : 1.0)
                    Circle().fill(speechService.isRecording ? Theme.primaryTeal : Theme.primaryTeal.opacity(0.8))
                        .frame(width: 100, height: 100)
                    Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36)).foregroundStyle(.white)
                }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: speechService.isRecording)
            .onChange(of: speechService.isRecording) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulseScale = 1.15 }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) { pulseScale = 1.0 }
                }
            }

            Text(speechService.isRecording ? "Listening..." : "Tap to speak")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(speechService.isRecording ? Theme.primaryTeal : Theme.textSecondary)

            if !speechService.transcript.isEmpty {
                ScrollView {
                    Text(speechService.transcript)
                        .font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                }
                .frame(maxHeight: 160)
                .background(Theme.inputBackground)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Type mode

    private var typeMode: some View {
        TextEditor(text: $typedText)
            .font(.system(size: 16))
            .scrollContentBackground(.hidden)
            .padding(16).frame(maxHeight: .infinity)
            .background(Theme.inputBackground)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(alignment: .topLeading) {
                if typedText.isEmpty {
                    Text("Write everything you want to work on.\nDon't organise it. Just get it out.")
                        .font(.system(size: 16)).foregroundStyle(Color(.placeholderText))
                        .padding(20).allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 24)
    }

    private var hasDump: Bool {
        let text = inputMode == .speak ? speechService.transcript : typedText
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

nonisolated enum InputMode: Sendable {
    case speak, type
}
