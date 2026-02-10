import SwiftUI

struct InstructionText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textStyle(.bodyS, color: .primary)
    }
}
