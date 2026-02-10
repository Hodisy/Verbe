import SwiftUI

struct SettingsPageTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .titleStyle(.large)
    }
}
