import SwiftUI

struct AutocompletionText: View {
    let inputText: String
    let completion: String
    let fontSize: CGFloat
    let alignment: Alignment
    let verticalPadding: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text(inputText)
                .foregroundStyle(.clear)
            Text(completion)
                .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
        }
        .font(.system(size: fontSize))
        .padding(.horizontal, 12)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}
