import SwiftUI

struct ShortcutsSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            SettingsPageTitle("Keyboard Shortcuts")

            Divider()

            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Current Hotkey")

                    HStack {
                        Text("⌘ Cmd + ⌥ Option")
                            .font(.system(.title3, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }

                    Divider()

                    Text("Customization coming soon")
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(30)
    }
}
