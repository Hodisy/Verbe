import SwiftUI

struct IconImageStyle {
    let variant: IconVariant
    let iconColor: Color?

    var dimension: CGFloat {
        switch variant {
        case .tiny: return Size.xs
        case .small: return Size.sm
        case .medium: return Size.md
        case .large: return Size.xl
        case .jumbo: return Size.xxxl
        }
    }
}

extension Image {
    func iconImageStyle(
        _ variant: IconVariant,
        color: Color? = nil
    ) -> some View {
        let style = IconImageStyle(variant: variant, iconColor: color)
        return self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: style.dimension, height: style.dimension)
            .foregroundColor(style.iconColor)
    }
}
