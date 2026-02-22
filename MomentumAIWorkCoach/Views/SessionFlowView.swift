import SwiftUI

struct SessionFlowView: View {
    @Environment(StorageService.self) private var storage
    @Environment(\.dismiss) private var dismiss

    @State private var currentPhase: SessionPhase = .brainDump
    @State private var blockNumber: Int = 1
    @State private var showEndConfirmation: Bool = false
    @State private var sessionStartTime: Date = Date()
    @State private var totalBlocksCompleted: Int = 0
    @State private var milestones: [Milestone] = []
    @State private var brainDump: String = ""
    @State private var blockDuration: Int = 25
    @State private var appMonitor = AppMonitorService()

    var body: some View {
        ZStack {
            switch currentPhase {
            case .brainDump:
                BrainDumpView { dump in
                    brainDump = dump
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPhase = .activation
                    }
                }

            case .activation:
                ActivationView(brainDump: brainDump) { newMilestones, duration in
                    milestones = newMilestones
                    blockDuration = duration
                    sessionStartTime = Date()
                    appMonitor.startMonitoring()
                    AppMonitorService.requestNotificationPermission()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPhase = .working
                    }
                }

            case .working:
                SessionScreenView(
                    blockNumber: blockNumber,
                    blockDuration: blockDuration,
                    context: brainDump,
                    milestones: $milestones,
                    onBlockComplete: {
                        totalBlocksCompleted += 1
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentPhase = .onBreak
                        }
                    },
                    onEndSession: {
                        showEndConfirmation = true
                    }
                )

            case .onBreak:
                BreakScreenView(
                    breakDuration: storage.userProfile.defaultBreakLength,
                    onBreakEnd: {
                        blockNumber += 1
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentPhase = .working
                        }
                    }
                )

            case .ended:
                SessionEndView(
                    totalDuration: Int(Date().timeIntervalSince(sessionStartTime) / 60),
                    blocksCompleted: max(totalBlocksCompleted, 1),
                    completedMilestones: milestones.filter(\.isCompleted),
                    onSave: { done, next in
                        let session = WorkSession(
                            date: sessionStartTime,
                            totalDuration: max(Int(Date().timeIntervalSince(sessionStartTime) / 60), 1),
                            blocksCompleted: max(totalBlocksCompleted, 1),
                            whatWasDone: done,
                            nextStep: next,
                            milestones: milestones,
                            brainDump: brainDump
                        )
                        storage.saveSession(session)
                        appMonitor.stopMonitoring()
                        dismiss()
                    }
                )
            }

            if appMonitor.showWelcomeBack {
                welcomeBackOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appMonitor.showWelcomeBack)
        .confirmationDialog(
            "End this session?",
            isPresented: $showEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session", role: .destructive) {
                totalBlocksCompleted += 1
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPhase = .ended
                }
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("You can always come back.")
        }
    }

    private var welcomeBackOverlay: some View {
        ZStack {
            Theme.primaryTeal.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Welcome back.")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)

                let minutes = appMonitor.timeAwaySeconds / 60
                Text("You were away for \(max(minutes, 1)) minute\(minutes == 1 ? "" : "s").")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.8))

                Button {
                    appMonitor.dismissWelcomeBack()
                } label: {
                    Text("Resume")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.primaryTeal)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(.white)
                        .clipShape(.rect(cornerRadius: 14))
                }
                .padding(.top, 8)
            }
        }
    }
}

nonisolated enum SessionPhase: Sendable {
    case brainDump, activation, working, onBreak, ended
}
