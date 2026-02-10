import SwiftUI

enum Typography {
    enum Role { case display, title, subtitle, body, label, caption, code, numeric }
    enum Size { case xxl, xl, lg, md, sm, xs }

    struct Token: Equatable {
        let role: Role
        let size: Size
        let weight: Font.Weight

        var font: Font {
            switch role {
            case .code:
                return .system(size: pointSize, weight: weight, design: .monospaced)
            case .numeric:
                return .system(size: pointSize, weight: weight).monospacedDigit()
            default:
                return .system(size: pointSize, weight: weight)
            }
        }

        private var pointSize: CGFloat {
            switch (role, size) {
            // Display - Title
            case (.display, .xxl): return 34
            case (.title, .xl): return 28
            case (.title, .lg): return 22
            case (.title, .md): return 18
            case (.title, .sm): return 16
            // Subtitle
            case (.subtitle, .md): return 15
            case (.subtitle, .sm): return 14
            // Body
            case (.body, .lg): return 16
            case (.body, .md): return 15
            case (.body, .sm): return 13
            case (.body, .xs): return 12
            // Label / Caption
            case (.label, .sm): return 12
            case (.caption, .xs): return 11
            // Code / Numeric
            case (.code, .md): return 14
            case (.code, .sm): return 13
            case (.numeric, .md): return 15
            case (.numeric, .sm): return 13
            default: return 14
            }
        }
    }

    // Titles
    static let displayXXL: Font = Token(role: .display, size: .xxl, weight: .bold).font
    static let titleXL: Font = Token(role: .title, size: .xl, weight: .bold).font
    static let titleL: Font = Token(role: .title, size: .lg, weight: .semibold).font
    static let titleM: Font = Token(role: .title, size: .md, weight: .medium).font
    static let titleS: Font = Token(role: .title, size: .sm, weight: .medium).font

    // Subtitles
    static let subtitleM: Font = Token(role: .subtitle, size: .md, weight: .regular).font
    static let subtitleS: Font = Token(role: .subtitle, size: .sm, weight: .regular).font

    // Body
    static let bodyL: Font = Token(role: .body, size: .lg, weight: .regular).font
    static let bodyM: Font = Token(role: .body, size: .md, weight: .regular).font
    static let bodyS: Font = Token(role: .body, size: .sm, weight: .regular).font
    static let bodyXS: Font = Token(role: .body, size: .xs, weight: .regular).font

    // Label / Caption
    static let labelS: Font = Token(role: .label, size: .sm, weight: .semibold).font
    static let captionXS: Font = Token(role: .caption, size: .xs, weight: .regular).font

    // Code / Numeric
    static let codeM: Font = Token(role: .code, size: .md, weight: .regular).font
    static let codeS: Font = Token(role: .code, size: .sm, weight: .regular).font
    static let numericM: Font = Token(role: .numeric, size: .md, weight: .regular).font
    static let numericS: Font = Token(role: .numeric, size: .sm, weight: .regular).font
}
