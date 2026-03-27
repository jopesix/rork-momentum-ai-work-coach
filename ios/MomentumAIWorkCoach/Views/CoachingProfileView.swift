import SwiftUI

struct CoachingProfileView: View {
    @Environment(StorageService.self) private var storage
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var coachingStyle: CoachingStyle = .encouraging
    @State private var patterns: String = ""
    @State private var notes: String = ""
    @State private var projects: [Project] = []
    @State private var newProjectName: String = ""
    @State private var showAddProject: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundMain.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        aboutYouSection
                        coachingStyleSection
                        projectsSection
                        patternsSection
                        notesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Coaching Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primaryTeal)
                }
            }
        }
        .onAppear { loadFromStorage() }
    }

    // MARK: - About You

    private var aboutYouSection: some View {
        sectionContainer(title: "ABOUT YOU") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your name")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                TextField("What should Mo call you?", text: $name)
                    .font(.system(size: 16)).padding(14)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    // MARK: - Coaching style

    private var coachingStyleSection: some View {
        sectionContainer(title: "COACHING STYLE") {
            VStack(spacing: 10) {
                ForEach(CoachingStyle.allCases, id: \.self) { style in
                    let isSelected = coachingStyle == style
                    Button { coachingStyle = style } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(isSelected ? Theme.primaryTeal : Theme.inputBackground)
                                .frame(width: 20, height: 20)
                                .overlay {
                                    if isSelected {
                                        Circle().fill(.white).frame(width: 8, height: 8)
                                    }
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                                if !isSelected {
                                    Text(style.description)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(isSelected ? Theme.primaryTeal : Theme.inputBackground)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Projects

    private var projectsSection: some View {
        sectionContainer(title: "YOUR PROJECTS") {
            VStack(spacing: 10) {
                ForEach($projects) { $project in
                    HStack(spacing: 10) {
                        Button {
                            project.isActive.toggle()
                        } label: {
                            Image(systemName: project.isActive ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(project.isActive ? Theme.primaryTeal : Theme.textSecondary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(project.isActive ? Theme.textPrimary : Theme.textSecondary)
                            if !project.description.isEmpty {
                                Text(project.description)
                                    .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Button {
                            projects.removeAll { $0.id == project.id }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13)).foregroundStyle(Theme.textSecondary.opacity(0.6))
                        }
                    }
                    .padding(12)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 10))
                }

                if projects.count < 10 {
                    if showAddProject {
                        HStack(spacing: 8) {
                            TextField("Project name", text: $newProjectName)
                                .font(.system(size: 14)).padding(.horizontal, 14).padding(.vertical, 10)
                                .background(Theme.inputBackground)
                                .clipShape(.rect(cornerRadius: 10))
                            if !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty {
                                Button {
                                    projects.append(Project(name: newProjectName.trimmingCharacters(in: .whitespaces)))
                                    newProjectName = ""
                                    showAddProject = false
                                } label: {
                                    Text("Add").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                        .padding(.horizontal, 14).padding(.vertical, 10)
                                        .background(Theme.primaryTeal).clipShape(.rect(cornerRadius: 10))
                                }
                            }
                        }
                    } else {
                        Button { showAddProject = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle").font(.system(size: 14))
                                Text("Add project").font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(Theme.primaryTeal)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Theme.inputBackground)
                            .clipShape(.rect(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Patterns

    private var patternsSection: some View {
        sectionContainer(title: "YOUR PATTERNS") {
            VStack(alignment: .leading, spacing: 8) {
                Text("What patterns has Mo noticed about how you work?")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                TextEditor(text: $patterns)
                    .font(.system(size: 15)).scrollContentBackground(.hidden)
                    .frame(minHeight: 80).padding(12)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(alignment: .topLeading) {
                        if patterns.isEmpty {
                            Text("e.g. \"loses momentum after lunch, works best in 25-min blocks\"")
                                .font(.system(size: 14)).foregroundStyle(Color(.placeholderText))
                                .padding(16).allowsHitTesting(false)
                        }
                    }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        sectionContainer(title: "COACHING NOTES") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Anything Mo should always know about how to support you?")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                TextEditor(text: $notes)
                    .font(.system(size: 15)).scrollContentBackground(.hidden)
                    .frame(minHeight: 80).padding(12)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("e.g. \"responds well to reframing tasks as small experiments\"")
                                .font(.system(size: 14)).foregroundStyle(Color(.placeholderText))
                                .padding(16).allowsHitTesting(false)
                        }
                    }
            }
        }
    }

    // MARK: - Helpers

    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.textSecondary).tracking(0.8)
            content()
        }
    }

    private func loadFromStorage() {
        let cp = storage.userProfile.coachingProfile
        name = cp.name
        coachingStyle = cp.coachingStyle
        patterns = cp.patterns
        notes = cp.notes
        projects = storage.userProfile.projects
    }

    private func save() {
        storage.userProfile.coachingProfile = CoachingProfile(
            name: name,
            coachingStyle: coachingStyle,
            patterns: patterns,
            notes: notes
        )
        storage.userProfile.projects = projects
        storage.saveProfile()
        dismiss()
    }
}
