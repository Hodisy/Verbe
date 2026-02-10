import SwiftUI

/// Liquid bubble view for recipe items
/// Matches ui-poc/styles.css .liquid-bubble
public struct LiquidBubbleView: View {
    let recipe: Recipe
    let isHovered: Bool

    private var size: CGFloat {
        isHovered ? 38 : 36
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(isHovered ? recipe.color.opacity(0.1) : Color.clear)
                .frame(width: size, height: size)

            Image(systemName: recipe.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(nsColor: .controlTextColor))
                .scaleEffect(isHovered ? 1 : 0.8)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .glassEffect()
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}
