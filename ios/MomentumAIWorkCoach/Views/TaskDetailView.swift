import SwiftUI

struct TaskDetailView: View {
    let task: MoTask
    let onStart: (MoTask) -> Void

    @Environment(StorageService.self) private var storage
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing: Bool = false
    @State private var editTitle: String = ""
    @State private var editNotes: String = ""
    @State private var editTag: String = ""

    // Sessions that worked on this task (matched by task title in startingTask)
    private var relatedSessions: [WorkSession] {
        storage.sessions.filter {
            $0.startingTask.localizedStandardContains(task.title) ||
            task.title.localizedStandardContains($0.startingTask)
        }
    }

    private var completedMilestones: [Milestone] {
        relatedSessions.flatMap { $0.milestones.filter(\.isCompleted) }
    }

    private var allMilestones: [Milestone] {
        relatedSessions.flatMap { $0.milestones }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundMain.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard
                        if task.status == .pending { startButton }
                        if !allMilestones.isEmpty { milestonesSection }
                        else if task.status == .pending { milestoneHint }
                        if !relatedSessions.isEmpty { sessionHistorySection }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") { saveEdits() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.primaryTeal)
                    } else if task.status == .pending {
                        Button { isEditing = true } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Theme.primaryTeal)
                        }
                    }
                }
            }
        }
        .onAppear {
            editTitle = task.title
            editNotes = task.notes
            editTag = task.projectTag ?? ""
        }
    }

    // MARK: - Header card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                editingForm
            } else {
                staticHeader
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var staticHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if let tag = task.projectTag {
                        Text(tag)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.primaryTeal)
                            .tracking(0.3)
                    }
                    Text(task.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                statusBadge
            }

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Added \(task.createdAt.formatted(.relative(presentation: .named)))")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
        }
    }

    private var editingForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TASK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.8)
                TextField("Task title", text: $editTitle)
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.8)
                TextField("Any context for Mo...", text: $editNotes)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("PROJECT TAG")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.8)
                TextField("Project name...", text: $editTag)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 10))
            }
        }
    }

    private var statusBadge: some View {
        Text(task.status == .done ? "Done" : "Pending")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(task.status == .done ? Theme.primaryTeal : Theme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(task.status == .done ? Theme.primaryLight : Theme.inputBackground)
            .clipShape(Capsule())
    }

    // MARK: - Start button

    private var startButton: some View {
        Button {
            dismiss()
            onStart(task)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(.system(size: 14))
                Text("Start Session with Mo")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.primaryTeal)
            .clipShape(.rect(cornerRadius: 14))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: false)
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MILESTONES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)

            VStack(spacing: 6) {
                ForEach(allMilestones.prefix(8)) { milestone in
                    HStack(spacing: 10) {
                        Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundStyle(milestone.isCompleted ? Theme.primaryTeal : Theme.border)
                        Text(milestone.title)
                            .font(.system(size: 14))
                            .foregroundStyle(milestone.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                            .strikethrough(milestone.isCompleted, color: Theme.textSecondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.cardBackground)
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
    }

    private var milestoneHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(Theme.primaryTeal)
            Text("Mo will generate milestones when you start a session.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Session history

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SESSION HISTORY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)

            VStack(spacing: 8) {
                ForEach(relatedSessions.prefix(3)) { session in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.date.formatted(.dateTime.month().day().year()))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(session.totalDuration) min · \(session.milestones.filter(\.isCompleted).count) milestones done")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.primaryTeal.opacity(0.6))
                    }
                    .padding(12)
                    .background(Theme.cardBackground)
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Helpers

    private func saveEdits() {
        guard let idx = storage.userProfile.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        storage.userProfile.tasks[idx].title = editTitle.trimmingCharacters(in: .whitespaces)
        storage.userProfile.tasks[idx].notes = editNotes.trimmingCharacters(in: .whitespaces)
        storage.userProfile.tasks[idx].projectTag = editTag.trimmingCharacters(in: .whitespaces).isEmpty ? nil : editTag.trimmingCharacters(in: .whitespaces)
        storage.saveProfile()
        isEditing = false
    }
}
