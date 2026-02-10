import SwiftUI

/// Tooltip for bubble components
/// Uses liquid glass effect to match LiquidBubbleView
struct BubbleTooltip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.3)
            .foregroundStyle(Color(nsColor: .controlTextColor))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect()
    }
}
