import SwiftUI

struct VoiceSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            SettingsPageTitle("Voice Settings")

            Divider()

            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Coming Soon")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    HintText("Voice command features are in development.")
                    HintText("• Fn key tap timing will be auto-detected")
                    HintText("• Microphone selection")
                    HintText("• Audio level monitoring")
                }
            }

            Spacer()
        }
        .padding(30)
    }
}
