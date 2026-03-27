import SwiftUI
import UIKit

struct SessionScreenView: View {
    let blockNumber: Int
    let blockDuration: Int
    let session: WorkSession
    @Binding var milestones: [Milestone]
    let onBlockComplete: () -> Void
    let onEndSession: () -> Void

    @Environment(StorageService.self) private var storage

    // Timer state — timestamp-based so it survives backgrounding
    @State private var timerEndDate: Date? = nil
    @State private var timeRemaining: Int = 0
    @State private var totalSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    @State private var selectedPreset: Int = 25
    @State private var showBlockComplete: Bool = false

    // Mo widget + speaker
    @State private var showMoWidget: Bool = false
    @State private var moContext: String = ""
    @State private var speaker = MoSpeaker()

    // Check-ins
    @State private var elapsedSeconds: Int = 0
    @State private var checkInNumber: Int = 0
    @State private var showCheckIn: Bool = false

    // Stuck
    @State private var showStuckPicker: Bool = false

    private let presets = [5, 10, 15, 25, 30, 45, 60]

    var body: some View {
        ZStack {
            Theme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar.padding(.top, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        if !milestones.isEmpty { milestoneStrip }
                        timerSection
                        stuckButton
                        talkToMoButton
                        if showMoWidget {
                            moSection.transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }

            if showCheckIn {
                checkInBanner.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            timeRemaining = blockDuration * 60
            totalSeconds = blockDuration * 60
            selectedPreset = blockDuration
            moContext = buildContext()
            // Mo speaks the opening message automatically on session start
            let opening = session.moOpeningMessage.isEmpty
                ? "Alright, let's get into it. Timer's ready when you are."
                : session.moOpeningMessage
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                speaker.speak(opening)
            }
        }
        .onDisappear {
            timer?.invalidate()
            speaker.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            recalculateTimerFromBackground()
        }
        .sheet(isPresented: $showBlockComplete) {
            blockCompleteSheet
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showStuckPicker) {
            stuckPickerSheet
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
        }
        .animation(.snappy, value: showMoWidget)
        .animation(.spring(response: 0.4), value: showCheckIn)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Color.clear.frame(width: 60, height: 1)
            Spacer()
            Text("WORK BLOCK \(blockNumber)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
            Spacer()
            Button { onEndSession() } label: {
                Text("End")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.inputBackground)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Milestones

    private var milestoneStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(milestones) { milestone in milestoneChip(milestone) }
            }
        }
        .contentMargins(.horizontal, 4)
        .scrollIndicators(.hidden)
    }

    private func milestoneChip(_ milestone: Milestone) -> some View {
        Button {
            if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
                withAnimation(.snappy) { milestones[index].isCompleted.toggle() }
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
            .background(milestone.isCompleted ? Theme.primaryLight : Theme.inputBackground)
            .clipShape(Capsule())
            .opacity(milestone.isCompleted ? 0.7 : 1)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: milestone.isCompleted)
    }

    // MARK: - Timer

    private var timerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 3)
                    .frame(width: 220, height: 220)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.primaryTeal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
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
                Button { pauseTimer() } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Theme.primaryTeal)
                        .clipShape(.rect(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 14) {
                    Button { startTimer() } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Theme.primaryTeal)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                    if timeRemaining < totalSeconds && timeRemaining > 0 {
                        Button { resetTimer() } label: {
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
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(isSelected ? Theme.primaryTeal : Theme.inputBackground)
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

    // MARK: - Stuck button

    private var stuckButton: some View {
        Button { showStuckPicker = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.heart").font(.system(size: 14))
                Text("I'm Stuck").font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent.opacity(0.1))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Talk to Mo

    private var talkToMoButton: some View {
        Button { withAnimation(.snappy) { showMoWidget.toggle() } } label: {
            HStack(spacing: 8) {
                Image(systemName: "waveform").font(.system(size: 14))
                Text("Talk to Mo").font(.system(size: 15, weight: .medium))
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
                    Image(systemName: "waveform.circle").font(.system(size: 28))
                        .foregroundStyle(Theme.primaryTeal.opacity(0.5))
                    Text("Voice coaching is being set up")
                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
            } else {
                MoWidgetView(agentId: Constants.elevenlabsAgentId, context: moContext)
                    .frame(height: 180).clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(16).frame(maxWidth: .infinity)
        .background(Theme.cardBackground).clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    // MARK: - Check-in banner

    private var checkInBanner: some View {
        VStack {
            HStack(spacing: 12) {
                MoPresenceIndicator()
                VStack(alignment: .leading, spacing: 2) {
                    Text(checkInMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tap to talk to Mo")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button { withAnimation { showCheckIn = false } } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 20))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16).background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: 14))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .padding(.horizontal, 16).padding(.top, 8)
            .onTapGesture {
                withAnimation { showCheckIn = false }
                moContext = buildContext(checkInNumber: checkInNumber)
                withAnimation(.snappy) { showMoWidget = true }
            }
            Spacer()
        }
    }

    private var checkInMessage: String {
        switch checkInNumber {
        case 1: return "Hey — 10 minutes in. How's it going?"
        case 2: return "Checking in. Still on track?"
        default: return "Mo is checking in. Need anything?"
        }
    }

    // MARK: - Stuck picker sheet

    private var stuckPickerSheet: some View {
        VStack(spacing: 20) {
            Text("What kind of stuck?")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            VStack(spacing: 10) {
                ForEach(StuckType.allCases, id: \.self) { type in
                    Button {
                        showStuckPicker = false
                        moContext = buildContext(stuckType: type)
                        // Mo speaks an immediate coaching line, then widget opens for deeper chat
                        speaker.speak(stuckCoachingLine(for: type))
                        withAnimation(.snappy) { showMoWidget = true }
                    } label: {
                        HStack {
                            Text(type.displayName).font(.system(size: 16)).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 18).padding(.vertical, 16)
                        .background(Theme.inputBackground)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 24)
    }

    // MARK: - Block complete sheet

    private var blockCompleteSheet: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 36))
                    .foregroundStyle(Theme.primaryTeal)
                Text("Block complete.")
                    .font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("Take a real break. Step away.")
                    .font(.system(size: 16)).foregroundStyle(Theme.textSecondary)
            }
            VStack(spacing: 10) {
                Button { showBlockComplete = false; onBlockComplete() } label: {
                    Text("Start 5 min break").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Theme.primaryTeal).clipShape(.rect(cornerRadius: 14))
                }
                Button { showBlockComplete = false; resetTimer() } label: {
                    Text("Keep going").font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(24)
    }

    // MARK: - Timer logic

    private func startTimer() {
        let end = Date().addingTimeInterval(TimeInterval(timeRemaining))
        timerEndDate = end
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in tick() }
    }

    private func pauseTimer() {
        timer?.invalidate(); isRunning = false; timerEndDate = nil
    }

    private func resetTimer() {
        timer?.invalidate()
        isRunning = false; timerEndDate = nil
        timeRemaining = selectedPreset * 60
        totalSeconds = selectedPreset * 60
        elapsedSeconds = 0; checkInNumber = 0
    }

    private func tick() {
        guard timeRemaining > 0 else { timerFinished(); return }
        timeRemaining -= 1
        elapsedSeconds += 1
        checkForCheckIns()
    }

    private func recalculateTimerFromBackground() {
        guard isRunning, let end = timerEndDate else { return }
        let remaining = Int(end.timeIntervalSinceNow)
        if remaining <= 0 { timerFinished() } else {
            timeRemaining = remaining
            elapsedSeconds = totalSeconds - remaining
        }
    }

    private func timerFinished() {
        timer?.invalidate(); isRunning = false; timerEndDate = nil; timeRemaining = 0
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showBlockComplete = true
    }

    private func checkForCheckIns() {
        // First check-in at exactly 10 minutes elapsed
        if checkInNumber == 0 && elapsedSeconds == 600 {
            triggerCheckIn(number: 1)
            return
        }
        // Every 20 minutes after first check-in (at 10+20=30 min, 30+20=50 min, etc.)
        if checkInNumber > 0 {
            let nextCheckInAt = 600 + checkInNumber * 1200
            if elapsedSeconds == nextCheckInAt {
                triggerCheckIn(number: checkInNumber + 1)
            }
        }
    }

    private func triggerCheckIn(number: Int) {
        checkInNumber = number
        moContext = buildContext(checkInNumber: number)
        withAnimation(.spring(response: 0.4)) { showCheckIn = true }
        // Mo speaks the check-in aloud automatically
        speaker.speak(checkInMessage)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            withAnimation { showCheckIn = false }
        }
    }

    // MARK: - Context builder

    private func buildContext(checkInNumber: Int = 0, stuckType: StuckType? = nil) -> String {
        let stuck: StuckContext? = stuckType.map {
            StuckContext(minutesIntoSession: elapsedSeconds / 60, currentTask: session.startingTask, stuckType: $0)
        }
        return MoContextBuilder.build(
            profile: storage.userProfile,
            session: session,
            phase: .working,
            elapsedMinutes: elapsedSeconds / 60,
            checkInNumber: checkInNumber,
            stuckContext: stuck,
            totalSessions: storage.totalSessionCount,
            totalHours: storage.totalHours
        )
    }

    private func stuckCoachingLine(for type: StuckType) -> String {
        let name = storage.userProfile.coachingProfile.name
        let n = name.isEmpty ? "" : "\(name), "
        switch type {
        case .overwhelm:
            return "\(n)let's zoom all the way in. Forget everything else. What's one tiny thing you can do right now?"
        case .distraction:
            return "It happens. You're back now — that's what matters. Let's pick up exactly where you left off."
        case .unclear:
            return "\(n)if the task feels fuzzy, it's hard to start. Tell me what you're trying to do and we'll make it concrete."
        case .lowEnergy:
            return "Low energy is real. You don't have to push through everything. What's the easiest version of this task?"
        }
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - timeRemaining) / Double(totalSeconds)
    }

    private var timeString: String {
        String(format: "%d:%02d", timeRemaining / 60, timeRemaining % 60)
    }
}
