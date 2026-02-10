import SwiftUI

/// A glass-effect circular button with an animated icon
struct GlassIconButton: View {
    let icon: String
    let size: CGFloat
    let iconSize: CGFloat
    let iconColor: Color
    let iconScale: CGFloat
    let isBouncing: Bool
    let isRepeatingBounce: Bool
    let glassID: String?
    let namespace: Namespace.ID?
    let onTap: () -> Void

    init(
        icon: String,
        size: CGFloat = 48,
        iconSize: CGFloat = 20,
        iconColor: Color = .white,
        iconScale: CGFloat = 1.0,
        isBouncing: Bool = false,
        isRepeatingBounce: Bool = false,
        glassID: String? = nil,
        namespace: Namespace.ID? = nil,
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.iconSize = iconSize
        self.iconColor = iconColor
        self.iconScale = iconScale
        self.isBouncing = isBouncing
        self.isRepeatingBounce = isRepeatingBounce
        self.glassID = glassID
        self.namespace = namespace
        self.onTap = onTap
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(iconColor)
                .scaleEffect(iconScale)
                .symbolEffect(.bounce.up.byLayer, options: .speed(1.1), value: isBouncing)
                .symbolEffect(.bounce.up.byLayer, options: .repeating.speed(1.1), isActive: isRepeatingBounce)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .modifier(GlassEffectModifier(glassID: glassID, namespace: namespace))
        .onTapGesture(perform: onTap)
    }
}

/// Conditional glass effect modifier
private struct GlassEffectModifier: ViewModifier {
    let glassID: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let id = glassID, let ns = namespace {
            content
                .glassEffect()
                .glassEffectID(id, in: ns)
        } else {
            content.glassEffect()
        }
    }
}
