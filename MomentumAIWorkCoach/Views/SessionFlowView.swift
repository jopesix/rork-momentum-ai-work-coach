import SwiftUI

struct SessionFlowView: View {
    var sourceTask: MoTask? = nil

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

    // Session data from Claude
    @State private var activeSession: WorkSession = WorkSession()

    var body: some View {
        ZStack {
            switch currentPhase {
            case .brainDump:
                // Back button overlay for brain dump screen
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16))
                            }
                            .foregroundStyle(Theme.primaryTeal)
                            .padding(.leading, 16)
                            .padding(.top, 8)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(1)

                BrainDumpView(
                    carryForwardContext: storage.userProfile.lastSessionContext,
                    activeProjects: storage.activeProjects,
                    selectedProjectName: activeSession.projectName
                ) { dump, projectName in
                    brainDump = dump
                    activeSession.brainDump = dump
                    activeSession.projectName = projectName
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPhase = .activation
                    }
                }

            case .activation:
                // Back button: to brain dump (quick session) or dismiss (task-based)
                VStack {
                    HStack {
                        Button {
                            if sourceTask != nil {
                                dismiss()
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) { currentPhase = .brainDump }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16))
                            }
                            .foregroundStyle(Theme.primaryTeal)
                            .padding(.leading, 16)
                            .padding(.top, 8)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(1)

                ActivationView(
                    brainDump: brainDump,
                    projectName: activeSession.projectName
                ) { newMilestones, duration, startingTask, suggestedMilestones, moOpening in
                    milestones = newMilestones
                    blockDuration = duration
                    activeSession.startingTask = startingTask
                    activeSession.suggestedMilestones = suggestedMilestones
                    activeSession.moOpeningMessage = moOpening
                    activeSession.milestones = newMilestones
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
                    session: activeSession,
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
                    session: activeSession,
                    onSave: { done, next in
                        var finalSession = activeSession
                        finalSession.date = sessionStartTime
                        finalSession.totalDuration = max(Int(Date().timeIntervalSince(sessionStartTime) / 60), 1)
                        finalSession.blocksCompleted = max(totalBlocksCompleted, 1)
                        finalSession.whatWasDone = done
                        finalSession.nextStep = next
                        finalSession.milestones = milestones
                        storage.recordSessionCompletion(finalSession)
                        if let task = sourceTask {
                            storage.completeTask(id: task.id)
                        }
                        appMonitor.stopMonitoring()
                        dismiss()
                    },
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.4)) { currentPhase = .working }
                    }
                )
            }

            if appMonitor.showWelcomeBack {
                welcomeBackOverlay.transition(.opacity)
            }
        }
        .onAppear {
            if let task = sourceTask {
                let context = [task.title, task.notes]
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                brainDump = context
                activeSession.brainDump = context
                activeSession.projectName = task.projectTag
                currentPhase = .activation
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
                withAnimation(.easeInOut(duration: 0.4)) { currentPhase = .ended }
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("You can always come back.")
        }
    }

    private var welcomeBackOverlay: some View {
        ZStack {
            Theme.primaryTeal.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Welcome back.")
                    .font(.system(size: 24, weight: .semibold)).foregroundStyle(.white)
                let minutes = appMonitor.timeAwaySeconds / 60
                Text("You were away for \(max(minutes, 1)) minute\(minutes == 1 ? "" : "s").")
                    .font(.system(size: 16)).foregroundStyle(.white.opacity(0.8))
                Button { appMonitor.dismissWelcomeBack() } label: {
                    Text("Resume")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.primaryTeal)
                        .padding(.horizontal, 40).padding(.vertical, 14)
                        .background(.white).clipShape(.rect(cornerRadius: 14))
                }
                .padding(.top, 8)
            }
        }
    }
}

nonisolated enum SessionPhase: Sendable {
    case brainDump, activation, working, onBreak, ended
}
