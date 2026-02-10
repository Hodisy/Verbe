import SwiftUI

struct SectionHeader: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .titleStyle(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
