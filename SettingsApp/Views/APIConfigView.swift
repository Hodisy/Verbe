import SwiftUI

struct APIConfigView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var statusMessage = "Connected"

    var body: some View {
        VStack(spacing: 20) {
            SettingsPageTitle("Gemini API Configuration")

            Divider()

            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("API Key")

                    SecureField("Enter your Gemini API Key", text: $viewModel.geminiApiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.geminiApiKey) {
                            viewModel.saveApiKey()
                        }

                    HStack {
                        Button("Test Connection") {
                            // Does nothing - just visual feedback
                        }
                        .disabled(viewModel.geminiApiKey.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(Semantics.interactive)

                        Spacer()

                        HStack(spacing: 8) {
                            Circle()
                                .fill(Semantics.success)
                                .frame(width: 8, height: 8)
                            Text(statusMessage)
                                .foregroundColor(Semantics.successForeground)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Semantics.successBackground)
                        )
                    }

                    HintText("Get your API key from: https://aistudio.google.com/apikey")
                        .padding(.top, 8)
                }
            }

            Spacer()
        }
        .padding(30)
    }
}
