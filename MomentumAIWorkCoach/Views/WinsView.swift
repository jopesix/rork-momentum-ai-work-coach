import SwiftUI

struct WinsView: View {
    @Environment(StorageService.self) private var storage
    @State private var searchText: String = ""
    @State private var selectedFilter: WinFilter = .all
    @State private var selectedSession: WorkSession?

    private var filteredSessions: [WorkSession] {
        var result = storage.sessions
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

        if !searchText.isEmpty {
            result = result.filter {
                $0.whatWasDone.localizedStandardContains(searchText) ||
                $0.brainDump.localizedStandardContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundMain.ignoresSafeArea()

                if storage.sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Here's everything you've done.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Theme.textSecondary)
                                TextField("Search your wins", text: $searchText)
                                    .font(.system(size: 15))
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 12))

                            ScrollView(.horizontal) {
                                HStack(spacing: 8) {
                                    ForEach(WinFilter.allCases, id: \.self) { filter in
                                        filterChip(filter)
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)

                            if filteredSessions.isEmpty {
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
                            } else {
                                ForEach(filteredSessions) { session in
                                    winCard(session)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Wins")
            .sheet(item: $selectedSession) { session in
                sessionDetailSheet(session)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
        }
    }

    private func filterChip(_ filter: WinFilter) -> some View {
        let isSelected = selectedFilter == filter
        return Button {
            selectedFilter = filter
        } label: {
            Text(filter.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.primaryTeal : Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
    }

    private func winCard(_ session: WorkSession) -> some View {
        Button {
            selectedSession = session
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Theme.primaryTeal)
                    .frame(width: 8, height: 8)
                    .padding(.top, 7)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(session.date, style: .date)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("\(session.totalDuration) min · \(session.blocksCompleted) block\(session.blocksCompleted == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    if !session.whatWasDone.isEmpty {
                        Text(session.whatWasDone)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    let completed = session.milestones.filter(\.isCompleted)
                    if !completed.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(completed) { milestone in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.primaryTeal)
                                    Text(milestone.title)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }

                    if !session.nextStep.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                            Text(session.nextStep)
                                .lineLimit(1)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.primaryTeal)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(.rect(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }

    private func sessionDetailSheet(_ session: WorkSession) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Session complete")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.primaryTeal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.primaryLight)
                            .clipShape(Capsule())
                        Spacer()
                    }

                    Text(session.date, style: .date)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)

                    HStack(spacing: 12) {
                        statItem("\(session.totalDuration)", label: "minutes")
                        statItem("\(session.blocksCompleted)", label: "blocks")
                    }

                    if !session.whatWasDone.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WHAT WAS DONE")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .tracking(0.5)
                            Text(session.whatWasDone)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }

                    let completed = session.milestones.filter(\.isCompleted)
                    if !completed.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MILESTONES COMPLETED")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .tracking(0.5)
                            ForEach(completed) { milestone in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.primaryTeal)
                                    Text(milestone.title)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                    }

                    if !session.nextStep.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NEXT STEP")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .tracking(0.5)
                            Text(session.nextStep)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.primaryTeal)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Session Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func statItem(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.primaryLight)
        .clipShape(.rect(cornerRadius: 12))
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
                Text("Every completed session adds to this list.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

nonisolated enum WinFilter: String, CaseIterable, Sendable {
    case all = "All"
    case thisWeek = "This week"
    case thisMonth = "This month"
}
