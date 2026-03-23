import SwiftUI

// MARK: - Win entry model

private enum WinEntryType {
    case sessionSummary(duration: Int, blocks: Int)
    case completedTask
    case milestone(parent: String)
}

private struct WinEntry: Identifiable {
    let id: String
    let type: WinEntryType
    let title: String
    let projectTag: String?
    let date: Date
}

// MARK: - Filter

nonisolated enum WinFilter: String, CaseIterable, Sendable {
    case all = "All"
    case thisWeek = "This week"
    case thisMonth = "This month"
}

// MARK: - View

struct WinsView: View {
    @Environment(StorageService.self) private var storage
    @State private var selectedFilter: WinFilter = .all
    @State private var selectedProjectTag: String? = nil
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundMain.ignoresSafeArea()

                if allWins.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            searchBar

                            filterRow

                            if !allProjectTags.isEmpty {
                                projectTagRow
                            }

                            let wins = filteredWins
                            if wins.isEmpty {
                                noMatchState
                            } else {
                                ForEach(groupedByDate(wins), id: \.0) { dateLabel, entries in
                                    dateSection(label: dateLabel, entries: entries)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Wins")
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
            TextField("Search your wins", text: $searchText)
                .font(.system(size: 15))
        }
        .padding(12)
        .background(Theme.inputBackground)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var filterRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(WinFilter.allCases, id: \.self) { filter in
                    filterChip(filter.rawValue, isSelected: selectedFilter == filter) {
                        selectedFilter = filter
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var projectTagRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterChip("All projects", isSelected: selectedProjectTag == nil) {
                    selectedProjectTag = nil
                }
                ForEach(allProjectTags, id: \.self) { tag in
                    filterChip(tag, isSelected: selectedProjectTag == tag) {
                        selectedProjectTag = selectedProjectTag == tag ? nil : tag
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func dateSection(label: String, entries: [WinEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)
                .padding(.top, 4)

            ForEach(entries) { entry in
                winCard(entry)
            }
        }
    }

    private func winCard(_ entry: WinEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            winIcon(entry.type)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    if let tag = entry.projectTag {
                        Text(tag)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.primaryTeal)
                    }

                    switch entry.type {
                    case .sessionSummary(let duration, let blocks):
                        Text("\(duration) min · \(blocks) block\(blocks == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    case .completedTask:
                        Text("Task completed")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    case .milestone(let parent):
                        if !parent.isEmpty {
                            Text("from: \(parent)")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func winIcon(_ type: WinEntryType) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case .sessionSummary: return ("sun.max.fill", Theme.primaryTeal)
            case .completedTask: return ("checkmark.circle.fill", .green)
            case .milestone: return ("flag.checkered", Theme.primaryTeal.opacity(0.7))
            }
        }()
        return ZStack {
            Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
            Image(systemName: icon).font(.system(size: 15)).foregroundStyle(color)
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Theme.primaryTeal : Theme.inputBackground)
                .clipShape(Capsule())
        }
    }

    private var noMatchState: some View {
        VStack(spacing: 8) {
            Text("No matches")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text("Try a different search or filter.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecondary.opacity(0.4))
            VStack(spacing: 4) {
                Text("Your wins appear here")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("Completed tasks, session summaries, and milestones all show up here.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Data

    private var allWins: [WinEntry] {
        var entries: [WinEntry] = []

        for session in storage.sessions {
            if !session.whatWasDone.isEmpty {
                entries.append(WinEntry(
                    id: "sess_\(session.id)",
                    type: .sessionSummary(duration: session.totalDuration, blocks: session.blocksCompleted),
                    title: session.whatWasDone,
                    projectTag: session.projectName,
                    date: session.date
                ))
            }
            for milestone in session.milestones.filter(\.isCompleted) {
                entries.append(WinEntry(
                    id: "ms_\(milestone.id)",
                    type: .milestone(parent: session.startingTask),
                    title: milestone.title,
                    projectTag: session.projectName,
                    date: session.date
                ))
            }
        }

        for task in storage.completedTasks {
            entries.append(WinEntry(
                id: "task_\(task.id)",
                type: .completedTask,
                title: task.title,
                projectTag: task.projectTag,
                date: task.completedAt ?? task.createdAt
            ))
        }

        return entries.sorted { $0.date > $1.date }
    }

    private var allProjectTags: [String] {
        Array(Set(allWins.compactMap(\.projectTag))).sorted()
    }

    private var filteredWins: [WinEntry] {
        var result = allWins
        let calendar = Calendar.current

        switch selectedFilter {
        case .all: break
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            result = result.filter { $0.date >= start }
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            result = result.filter { $0.date >= start }
        }

        if let tag = selectedProjectTag {
            result = result.filter { $0.projectTag == tag }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedStandardContains(searchText) }
        }

        return result
    }

    private func groupedByDate(_ entries: [WinEntry]) -> [(String, [WinEntry])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var seen: [String: [WinEntry]] = [:]
        var order: [String] = []

        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            let label: String
            if day == today {
                label = "Today"
            } else if day == yesterday {
                label = "Yesterday"
            } else {
                label = entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day())
            }

            if seen[label] == nil {
                seen[label] = []
                order.append(label)
            }
            seen[label]!.append(entry)
        }

        return order.map { ($0, seen[$0]!) }
    }
}
