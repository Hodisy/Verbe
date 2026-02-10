import SwiftUI

struct BodyText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textStyle(.bodyM, color: .primary)
    }
}
