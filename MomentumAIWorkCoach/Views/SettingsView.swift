import SwiftUI

struct SettingsView: View {
    @Environment(StorageService.self) private var storage

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundMain.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        coachingProfileSection
                        preferencesSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var coachingProfileSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)
                .padding(.bottom, 10)

            NavigationLink(destination: CoachingProfileView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coaching Profile")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                        let name = storage.userProfile.coachingProfile.name
                        Text(name.isEmpty ? "Tell Mo who you are" : "Hi \(name) — \(storage.userProfile.projects.filter(\.isActive).count) project\(storage.userProfile.projects.filter(\.isActive).count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PREFERENCES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                HStack {
                    Text("Block length")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Stepper(
                        "\(storage.userProfile.defaultBlockLength) min",
                        value: Binding(
                            get: { storage.userProfile.defaultBlockLength },
                            set: { newValue in
                                storage.userProfile.defaultBlockLength = newValue
                                storage.saveProfile()
                            }
                        ),
                        in: 5...120,
                        step: 5
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Break length")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Stepper(
                        "\(storage.userProfile.defaultBreakLength) min",
                        value: Binding(
                            get: { storage.userProfile.defaultBreakLength },
                            set: { newValue in
                                storage.userProfile.defaultBreakLength = newValue
                                storage.saveProfile()
                            }
                        ),
                        in: 1...30,
                        step: 1
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Mo checks in when you leave during a session")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { storage.userProfile.notificationsEnabled },
                        set: { newValue in
                            storage.userProfile.notificationsEnabled = newValue
                            storage.saveProfile()
                        }
                    ))
                    .tint(Theme.primaryTeal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ABOUT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                HStack {
                    Text("Momentum v1.0")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                Divider().padding(.leading, 16)

                Text("Mo is a voice AI coach, not a therapist. If you are in crisis, please reach out to a mental health professional.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(16)
            }
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: 12))
        }
    }
}
