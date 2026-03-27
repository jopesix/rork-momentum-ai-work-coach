import SwiftUI

struct AddTaskView: View {
    @Environment(StorageService.self) private var storage
    @Environment(\.dismiss) private var dismiss

    @State private var inputMode: InputMode = .type
    @State private var titleText: String = ""
    @State private var notes: String = ""
    @State private var selectedTag: String? = nil
    @State private var newTagText: String = ""
    @State private var speechService = SpeechService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    taskTitleSection
                    notesSection
                    projectTagSection
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveTask() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(hasTitle ? Theme.primaryTeal : Theme.textSecondary.opacity(0.5))
                        .disabled(!hasTitle)
                }
            }
        }
        .onAppear { speechService.requestAuthorization() }
        .onDisappear { speechService.stopRecording() }
    }

    // MARK: - Sections

    private var taskTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TASK")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)

            modeToggle

            if inputMode == .speak {
                voiceInput
            } else {
                TextField("What do you need to do?", text: $titleText)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES (optional)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)
            TextField("Any context that'll help Mo plan this", text: $notes)
                .font(.system(size: 15))
                .padding(14)
                .background(Theme.inputBackground)
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var projectTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROJECT (optional)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)

            let existingTags = storage.allProjectTags
            if !existingTags.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(existingTags, id: \.self) { tag in
                            tagChip(tag)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            HStack(spacing: 8) {
                TextField("New project...", text: $newTagText)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.inputBackground)
                    .clipShape(.rect(cornerRadius: 10))

                if !newTagText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        selectedTag = newTagText.trimmingCharacters(in: .whitespaces)
                        newTagText = ""
                    } label: {
                        Text("Use")
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
            .animation(.snappy, value: newTagText.isEmpty)

            if let tag = selectedTag {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill").font(.system(size: 11))
                    Text(tag).font(.system(size: 13, weight: .medium))
                    Button {
                        selectedTag = nil
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Theme.primaryTeal)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Helpers

    private var hasTitle: Bool {
        let text = inputMode == .speak ? speechService.transcript : titleText
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveTask() {
        let title: String
        if inputMode == .speak {
            title = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            title = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !title.isEmpty else { return }
        let task = MoTask(
            title: title,
            notes: notes.trimmingCharacters(in: .whitespaces),
            projectTag: selectedTag
        )
        storage.addTask(task)
        dismiss()
    }

    private func tagChip(_ tag: String) -> some View {
        let isSelected = selectedTag == tag
        return Button {
            selectedTag = isSelected ? nil : tag
        } label: {
            Text(tag)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Theme.primaryTeal : Theme.inputBackground)
                .clipShape(Capsule())
        }
    }

    // MARK: - Input controls

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton("Speak", icon: "mic.fill", mode: .speak)
            modeButton("Type", icon: "pencil", mode: .type)
        }
        .background(Theme.inputBackground)
        .clipShape(Capsule())
    }

    private func modeButton(_ label: String, icon: String, mode: InputMode) -> some View {
        let isSelected = inputMode == mode
        return Button {
            if speechService.isRecording { speechService.stopRecording() }
            inputMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .medium))
                Text(label).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(isSelected ? Theme.primaryTeal : .clear)
            .clipShape(Capsule())
        }
    }

    private var voiceInput: some View {
        VStack(spacing: 12) {
            Button {
                if speechService.isRecording { speechService.stopRecording() }
                else { speechService.startRecording() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24))
                    Text(speechService.isRecording ? "Stop recording" : "Tap to speak your task")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(speechService.isRecording ? .red : Theme.primaryTeal)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Theme.inputBackground).clipShape(.rect(cornerRadius: 12))
            }
            if !speechService.transcript.isEmpty {
                Text(speechService.transcript)
                    .font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .background(Theme.inputBackground).clipShape(.rect(cornerRadius: 10))
            }
        }
    }
}
