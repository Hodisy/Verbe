import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
    case recipes = "Recipes"
    case api = "API"
    case liveVoicePrompt = "Live Voice Prompt"
    case voiceCommandPrompt = "Voice Command Prompt"
    case shortcuts = "Shortcuts"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .recipes: return "star.fill"
        case .api: return "key.fill"
        case .liveVoicePrompt: return "waveform"
        case .voiceCommandPrompt: return "mic.badge.plus"
        case .shortcuts: return "command"
        }
    }
}

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var selectedPage: SettingsPage = .recipes

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $selectedPage) { page in
                Label(page.rawValue, systemImage: page.icon)
                    .tag(page)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            Group {
                switch selectedPage {
                case .recipes:
                    RecipesManagementView(viewModel: viewModel)
                case .api:
                    APIConfigView(viewModel: viewModel)
                case .liveVoicePrompt:
                    LiveVoicePromptSettingsView(viewModel: viewModel)
                case .voiceCommandPrompt:
                    VoiceCommandPromptSettingsView(viewModel: viewModel)
                case .shortcuts:
                    ShortcutsSettingsView()
                }
            }
        }
        .frame(width: 800, height: 600)
    }
}
