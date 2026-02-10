import SwiftUI

struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        switch selfStyle {
        case .headline:
            content.textStyle(.titleXL, color: .primary)
        case .large:
            content.textStyle(.titleL, color: .primary)
        case .medium:
            content.textStyle(.titleM, color: .secondary)
        case .small:
            content.textStyle(.titleS, color: .secondary)
        case .tiny:
            content.textStyle(.subtitleM, color: .secondary)
        case .micro:
            content.textStyle(.subtitleS, color: .tertiary)
        case .nano:
            content.textStyle(.captionXS, color: .tertiary)
        case .pico:
            content.textStyle(.captionXS, color: .inverse)
        }
    }

    private let selfStyle: TitleVariant
    init(_ style: TitleVariant) { selfStyle = style }
}

extension View {
    func titleStyle(_ style: TitleVariant) -> some View {
        modifier(TitleStyle(style))
    }
}
