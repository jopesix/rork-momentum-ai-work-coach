import SwiftUI

struct SessionScreenView: View {
    let blockNumber: Int
    let blockDuration: Int
    let context: String
    @Binding var milestones: [Milestone]
    let onBlockComplete: () -> Void
    let onEndSession: () -> Void

    @State private var timeRemaining: Int = 0
    @State private var totalSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    @State private var selectedPreset: Int = 25
    @State private var showBlockComplete: Bool = false
    @State private var showMoWidget: Bool = false

    private let presets = [5, 10, 15, 25, 30, 45, 60]

    var body: some View {
        ZStack {
            Theme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        if !milestones.isEmpty {
                            milestoneStrip
                        }

                        timerSection

                        talkToMoButton

                        if showMoWidget {
                            moSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            timeRemaining = blockDuration * 60
            totalSeconds = blockDuration * 60
            selectedPreset = blockDuration
        }
        .onDisappear { timer?.invalidate() }
        .sheet(isPresented: $showBlockComplete) {
            blockCompleteSheet
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
        }
    }

    private var topBar: some View {
        HStack {
            Color.clear.frame(width: 60, height: 1)
            Spacer()
            Text("WORK BLOCK \(blockNumber)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
            Spacer()
            Button {
                onEndSession()
            } label: {
                Text("End")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
    }

    private var milestoneStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(milestones) { milestone in
                    milestoneChip(milestone)
                }
            }
        }
        .contentMargins(.horizontal, 4)
        .scrollIndicators(.hidden)
    }

    private func milestoneChip(_ milestone: Milestone) -> some View {
        Button {
            if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
                withAnimation(.snappy) {
                    milestones[index].isCompleted.toggle()
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(milestone.isCompleted ? Theme.primaryTeal : Theme.textSecondary)
                Text(milestone.title)
                    .font(.system(size: 13, weight: .medium))
                    .strikethrough(milestone.isCompleted)
                    .foregroundStyle(milestone.isCompleted ? Theme.textSecondary : Theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(milestone.isCompleted ? Theme.primaryLight : Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .opacity(milestone.isCompleted ? 0.7 : 1)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: milestone.isCompleted)
    }

    private var timerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 3)
                    .frame(width: 220, height: 220)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.primaryTeal,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 52, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                    Text("minutes remaining")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.top, 8)

            if isRunning {
                Button {
                    pauseTimer()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.primaryTeal)
                        .clipShape(.rect(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 14) {
                    Button {
                        startTimer()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Theme.primaryTeal)
                            .clipShape(.rect(cornerRadius: 14))
                    }

                    if timeRemaining < totalSeconds && timeRemaining > 0 {
                        Button {
                            resetTimer()
                        } label: {
                            Text("Reset timer")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { preset in
                                let isSelected = selectedPreset == preset
                                Button {
                                    selectedPreset = preset
                                    timeRemaining = preset * 60
                                    totalSeconds = preset * 60
                                } label: {
                                    Text("\(preset)m")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Theme.primaryTeal : Color(.tertiarySystemFill))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .contentMargins(.horizontal, 4)
                    .scrollIndicators(.hidden)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var talkToMoButton: some View {
        Button {
            withAnimation(.snappy) {
                showMoWidget.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 14))
                Text("Talk to Mo")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Theme.primaryTeal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.primaryLight)
            .clipShape(.rect(cornerRadius: 12))
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showMoWidget)
    }

    private var moSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                MoPresenceIndicator()
                Text("MO IS HERE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.8)
            }

            if Constants.elevenlabsAgentId.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.primaryTeal.opacity(0.5))
                    Text("Voice coaching is being set up")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
            } else {
                Text("Tap the mic to speak to Mo")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)

                MoWidgetView(
                    agentId: Constants.elevenlabsAgentId,
                    context: context
                )
                .frame(height: 180)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    private var blockCompleteSheet: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.primaryTeal)
                Text("Block complete.")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Take a real break. Step away.")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 10) {
                Button {
                    showBlockComplete = false
                    onBlockComplete()
                } label: {
                    Text("Start 5 min break")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.primaryTeal)
                        .clipShape(.rect(cornerRadius: 14))
                }
                Button {
                    showBlockComplete = false
                    resetTimer()
                } label: {
                    Text("Keep going")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(24)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - timeRemaining) / Double(totalSeconds)
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                isRunning = false
                showBlockComplete = true
            }
        }
    }

    private func pauseTimer() {
        timer?.invalidate()
        isRunning = false
    }

    private func resetTimer() {
        timer?.invalidate()
        isRunning = false
        timeRemaining = selectedPreset * 60
        totalSeconds = selectedPreset * 60
    }
}
