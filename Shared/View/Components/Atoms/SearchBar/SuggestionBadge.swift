import SwiftUI

/// A glass pill badge displaying a suggestion label
struct SuggestionBadge: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(nsColor: .labelColor))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect()
            .onTapGesture(perform: onTap)
    }
}
