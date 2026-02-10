import SwiftUI

struct LiveVoicePromptSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var draftPrompt: String
    @State private var saveFeedback = ""

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        _draftPrompt = State(initialValue: viewModel.liveVoicePrompt)
    }

    var body: some View {
        PromptEditorPageView(
            title: "Live Voice Prompt",
            description: "Customize instructions used by the live voice assistant.",
            placeholder: "Enter a custom live voice prompt...",
            promptText: $draftPrompt,
            defaultPrompt: SettingsViewModel.defaultLiveVoicePrompt,
            saveFeedback: saveFeedback,
            onSave: {
                viewModel.liveVoicePrompt = draftPrompt
                viewModel.saveLiveVoicePrompt()
                saveFeedback = "Saved"
            }
        )
        .onAppear {
            draftPrompt = viewModel.liveVoicePrompt
        }
    }
}

struct VoiceCommandPromptSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var draftPrompt: String
    @State private var saveFeedback = ""

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        _draftPrompt = State(initialValue: viewModel.voiceCommandPrompt)
    }

    var body: some View {
        PromptEditorPageView(
            title: "Voice Command Prompt",
            description: "Customize instructions used for one-shot voice commands.",
            placeholder: "Enter a custom voice command prompt...",
            promptText: $draftPrompt,
            defaultPrompt: SettingsViewModel.defaultVoiceCommandPrompt,
            saveFeedback: saveFeedback,
            onSave: {
                viewModel.voiceCommandPrompt = draftPrompt
                viewModel.saveVoiceCommandPrompt()
                saveFeedback = "Saved"
            }
        )
        .onAppear {
            draftPrompt = viewModel.voiceCommandPrompt
        }
    }
}

private struct PromptEditorPageView: View {
    let title: String
    let description: String
    let placeholder: String
    @Binding var promptText: String
    let defaultPrompt: String
    let saveFeedback: String
    let onSave: () -> Void

    private var isUsingDefault: Bool {
        promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            SettingsPageTitle(title)

            Divider()

            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Prompt")
                    HintText(description)

                    ZStack(alignment: .topLeading) {
                        if promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(placeholder)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 12)
                        }
                        TextEditor(text: $promptText)
                            .frame(minHeight: 180)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            )
                    }

                    HStack {
                        Button("Save") {
                            onSave()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Semantics.interactive)

                        if !saveFeedback.isEmpty {
                            Text(saveFeedback)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    if isUsingDefault {
                        Text("Using default prompt (because custom prompt is empty):")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView {
                            Text(defaultPrompt)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(minHeight: 120, maxHeight: 180)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(8)
                    } else {
                        Text("Custom prompt is active.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(30)
    }
}
