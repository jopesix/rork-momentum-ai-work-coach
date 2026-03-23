import SwiftUI

struct HomeView: View {
    @Environment(StorageService.self) private var storage
    @State private var showSession: Bool = false
    @State private var selectedTask: MoTask? = nil
    @State private var showAddTask: Bool = false
    @State private var showDoneSection: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        quickSessionCard
                        tasksSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Mo")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.primaryTeal)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showSession, onDismiss: {
            selectedTask = nil
        }) {
            SessionFlowView(sourceTask: selectedTask)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
        }
    }

    // MARK: - Quick Session card

    private var quickSessionCard: some View {
        Button {
            selectedTask = nil
            showSession = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.primaryTeal.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: "bolt.fill").font(.system(size: 18)).foregroundStyle(Theme.primaryTeal)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Session")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Tell Mo what's on your mind")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
            }
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }

    // MARK: - Tasks section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TASKS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.8)
                Spacer()
                Button {
                    showAddTask = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        Text("Add").font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.primaryTeal)
                }
            }
            .padding(.bottom, 10)

            if storage.pendingTasks.isEmpty && storage.completedTasks.isEmpty {
                emptyTasksState
            } else {
                VStack(spacing: 8) {
                    ForEach(storage.pendingTasks) { task in
                        taskRow(task, done: false)
                    }

                    if !storage.completedTasks.isEmpty {
                        Button {
                            withAnimation(.snappy) { showDoneSection.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showDoneSection ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Done (\(storage.completedTasks.count))")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, 4).padding(.leading, 2)
                        }

                        if showDoneSection {
                            ForEach(storage.completedTasks.prefix(20)) { task in
                                taskRow(task, done: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func taskRow(_ task: MoTask, done: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(done ? Theme.primaryTeal.opacity(0.5) : Theme.border)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 15))
                    .foregroundStyle(done ? Theme.textSecondary : Theme.textPrimary)
                    .strikethrough(done, color: Theme.textSecondary)
                    .lineLimit(2)

                if let tag = task.projectTag {
                    Text(tag)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.primaryTeal.opacity(done ? 0.5 : 0.8))
                }
            }

            Spacer()

            if !done {
                Button {
                    selectedTask = task
                    showSession = true
                } label: {
                    Text("Start")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Theme.primaryTeal)
                        .clipShape(Capsule())
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: showSession)
            }
        }
        .padding(14)
        .background(Theme.cardBackground.opacity(done ? 0.6 : 1))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                storage.deleteTask(id: task.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyTasksState: some View {
        VStack(spacing: 12) {
            Text("No tasks yet.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text("Add a task or jump straight into a Quick Session.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                showAddTask = true
            } label: {
                Text("+ Add your first task")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.primaryTeal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32).padding(.horizontal, 16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: 14))
    }
}

extension Notification.Name {
    static let switchToWinsTab = Notification.Name("switchToWinsTab")
}
