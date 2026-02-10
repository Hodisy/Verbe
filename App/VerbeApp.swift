import SwiftUI

@main
struct VerbeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            Divider()
            Button("Settings") {
                appDelegate.openSettings()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image("menubarIcon")
        }
    }
}
