import SwiftUI

struct IconCircleStyle: ViewModifier {
    let variant: IconVariant
    let fillColor: Color?

    private var dimension: CGFloat {
        switch variant {
        case .tiny: return Size.xs
        case .small: return Size.sm
        case .medium: return Size.md
        case .large: return Size.xl
        case .jumbo: return Size.xxxl
        }
    }

    func body(content _: Content) -> some View {
        Circle()
            .fill(fillColor ?? .clear)
            .frame(width: dimension, height: dimension)
    }
}

extension View {
    func iconCircleStyle(
        _ variant: IconVariant,
        color: Color? = nil
    ) -> some View {
        modifier(IconCircleStyle(variant: variant, fillColor: color))
    }
}
