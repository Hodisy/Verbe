import SwiftUI

struct LabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        switch selfStyle {
        case .standard:
            content.textStyle(.labelS, color: .tertiary)
        case .important:
            content.textStyle(.labelS, color: .primary)
        case .disabled:
            content.textStyle(.labelS, color: .secondary)
        case .inverse:
            content.textStyle(.labelS, color: .inverse)
        }
    }

    private let selfStyle: LabelVariant
    init(_ style: LabelVariant) { selfStyle = style }
}

extension View {
    func labelStyle(_ style: LabelVariant) -> some View {
        modifier(LabelStyle(style))
    }
}
