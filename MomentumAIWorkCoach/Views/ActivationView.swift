import SwiftUI

struct ActivationView: View {
    let brainDump: String
    let projectName: String?
    /// milestones, duration, startingTask, suggestedMilestones, moOpeningMessage
    let onStart: ([Milestone], Int, String, [String], String) -> Void

    @Environment(StorageService.self) private var storage
    @State private var milestones: [Milestone] = []
    @State private var newMilestoneText: String = ""
    @State private var selectedDuration: Int = 25
    @State private var isCustom: Bool = false
    @State private var customDuration: String = ""
    @State private var showMilestones: Bool = true
    @State private var isProcessing: Bool = true
    @State private var startingTask: String = ""
    @State private var moOpeningMessage: String = ""
    @State private var aiSuggestedMilestones: [String] = []
    @State private var appeared: Bool = false

    private let durations = [15, 25, 45, 60]
    private let claudeService = ClaudeService()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if isProcessing {
                processingState
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        recommendationCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        moWidgetSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        milestoneSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        timerSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    Button {
                        let duration: Int
                        if isCustom, let custom = Int(customDuration), custom > 0 {
                            duration = custom
                        } else {
                            duration = selectedDuration
                        }
                        onStart(milestones, duration, startingTask, aiSuggestedMilestones, moOpeningMessage)
                    } label: {
                        Text("Let's go")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.primaryTeal)
                            .clipShape(.rect(cornerRadius: 16))
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: selectedDuration)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.bar)
                }
            }
        }
        .onAppear {
            selectedDuration = storage.userProfile.defaultBlockLength
            processTheDump()
        }
    }

    private var processingState: some View {
        VStack(spacing: 20) {
            MoPresenceIndicator()
            Text("Mo is sorting through that...")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("START HERE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.primaryTeal)
                .tracking(1)

            Text(startingTask)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !moOpeningMessage.isEmpty {
                Text(moOpeningMessage)
                    .font(.system(size: 15).italic())
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.primaryLight)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var moWidgetSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                MoPresenceIndicator()
                Text("TALK TO MO")
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
                MoWidgetView(
                    agentId: Constants.elevenlabsAgentId,
                    context: buildMoContext()
                )
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) { showMilestones.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showMilestones ? "chevron.down" : "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text(milestones.isEmpty ? "Add milestones for this session" : "Milestones (\(milestones.count))")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Theme.primaryTeal)
            }

            if showMilestones {
                VStack(spacing: 10) {
                    ForEach(milestones) { milestone in
                        HStack(spacing: 10) {
                            Circle()
                                .stroke(Theme.border, lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                            Text(milestone.title)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Button {
                                milestones.removeAll { $0.id == milestone.id }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 10))
                    }

                    if milestones.count < 5 {
                        HStack(spacing: 8) {
                            TextField("Add a step...", text: $newMilestoneText)
                                .font(.system(size: 14))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(.rect(cornerRadius: 10))

                            if !newMilestoneText.trimmingCharacters(in: .whitespaces).isEmpty {
                                Button {
                                    let milestone = Milestone(title: newMilestoneText.trimmingCharacters(in: .whitespaces))
                                    milestones.append(milestone)
                                    newMilestoneText = ""
                                } label: {
                                    Text("Add")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Theme.primaryTeal)
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.snappy, value: newMilestoneText.isEmpty)
                    }
                }
            }
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Work block length")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(durations, id: \.self) { duration in
                        let isSelected = !isCustom && selectedDuration == duration
                        Button {
                            isCustom = false
                            selectedDuration = duration
                        } label: {
                            Text("\(duration) min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(isSelected ? Theme.primaryTeal : Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                    }

                    Button {
                        isCustom = true
                    } label: {
                        Text("Custom")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isCustom ? .white : Theme.textPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(isCustom ? Theme.primaryTeal : Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
            }
            .scrollIndicators(.hidden)

            if isCustom {
                TextField("Enter minutes", text: $customDuration)
                    .font(.system(size: 16))
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private func buildMoContext() -> String {
        var session = WorkSession()
        session.brainDump = brainDump
        session.startingTask = startingTask
        session.suggestedMilestones = aiSuggestedMilestones
        session.moOpeningMessage = moOpeningMessage
        session.projectName = projectName
        return MoContextBuilder.build(
            profile: storage.userProfile,
            session: session,
            phase: .activation,
            totalSessions: storage.totalSessionCount,
            totalHours: storage.totalHours
        )
    }

    private func processTheDump() {
        Task {
            do {
                let result = try await claudeService.getActivationPlan(
                    brainDump: brainDump,
                    profile: storage.userProfile,
                    totalSessions: storage.totalSessionCount,
                    totalHours: storage.totalHours
                )
                await MainActor.run {
                    startingTask = result.startingTask
                    moOpeningMessage = result.moOpeningMessage
                    aiSuggestedMilestones = result.suggestedMilestones
                    // Pre-populate milestone list from Claude's suggestions
                    milestones = result.suggestedMilestones.map { Milestone(title: $0) }
                    showMilestones = !milestones.isEmpty
                    finishProcessing()
                }
            } catch {
                // Graceful fallback — never block the user
                await MainActor.run {
                    let lines = brainDump.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    startingTask = String((lines.first ?? brainDump).prefix(100))
                    moOpeningMessage = "You've got this. Let's get started."
                    finishProcessing()
                }
            }
        }
    }

    private func finishProcessing() {
        isProcessing = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            appeared = true
        }
    }
}
