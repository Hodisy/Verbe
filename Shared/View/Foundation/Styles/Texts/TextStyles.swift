import SwiftUI

struct TextStyle: ViewModifier {
    @Environment(\.theme) private var theme
    let variant: TextVariant
    let colorVariant: TextColorVariant

    func body(content: Content) -> some View {
        content
            .font(font(for: variant))
            .foregroundColor(color(for: colorVariant))
    }

    private func font(for variant: TextVariant) -> Font {
        switch variant {
        case .displayXXL: return Typography.displayXXL
        case .titleXL: return Typography.titleXL
        case .titleL: return Typography.titleL
        case .titleM: return Typography.titleM
        case .titleS: return Typography.titleS
        case .subtitleM: return Typography.subtitleM
        case .subtitleS: return Typography.subtitleS
        case .bodyL: return Typography.bodyL
        case .bodyM: return Typography.bodyM
        case .bodyS: return Typography.bodyS
        case .bodyXS: return Typography.bodyXS
        case .labelS: return Typography.labelS
        case .captionXS: return Typography.captionXS
        case .codeM: return Typography.codeM
        case .codeS: return Typography.codeS
        case .numericM: return Typography.numericM
        case .numericS: return Typography.numericS
        }
    }

    private func color(for variant: TextColorVariant) -> Color {
        switch variant {
        case .primary: return theme.text.primary
        case .secondary: return theme.text.secondary
        case .tertiary: return theme.text.tertiary
        case .inverse: return theme.text.inverse
        }
    }
}

extension View {
    func textStyle(_ variant: TextVariant, color: TextColorVariant = .primary) -> some View {
        modifier(TextStyle(variant: variant, colorVariant: color))
    }
}
