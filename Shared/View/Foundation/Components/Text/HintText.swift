import SwiftUI

struct HintText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textStyle(.captionXS, color: .secondary)
    }
}
