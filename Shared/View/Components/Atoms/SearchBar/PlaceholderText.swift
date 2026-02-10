import SwiftUI

/// Non-interactive placeholder text for empty input fields
struct PlaceholderText: View {
    let text: String
    let fontSize: CGFloat
    let alignment: Alignment
    let verticalPadding: CGFloat

    var body: some View {
        Text(text)
            .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
            .font(.system(size: fontSize))
            .padding(.horizontal, 12)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .allowsHitTesting(false)
    }
}
