import SwiftUI

struct Theme {
    struct Text {
        let primary = Semantics.textPrimary
        let secondary = Semantics.textSecondary
        let tertiary = Semantics.textTertiary
        let inverse = Semantics.textInverse
    }

    struct Background {
        let screen = LinearGradient(
            colors: [Semantics.background, Semantics.backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
        let card = Semantics.background
        let secondary = Semantics.backgroundSecondary
        let tertiary = Semantics.backgroundTertiary
    }

    struct Accent {
        let success = (
            foreground: Semantics.successForeground,
            background: Semantics.successBackground
        )
        let info = (
            foreground: Semantics.primary,
            background: Semantics.primaryBackground
        )
        let empathy = (
            foreground: Semantics.secondary,
            background: Semantics.secondaryBackground
        )
        let warning = (
            foreground: Semantics.warningForeground,
            background: Semantics.warningBackground
        )
        let error = (
            foreground: Semantics.errorForeground,
            background: Semantics.errorBackground
        )
    }

    struct Interactive {
        let primary = Semantics.interactive
        let hover = Semantics.interactiveHover
        let active = Semantics.interactiveActive
        let disabled = Semantics.interactiveDisabled
    }

    struct Border {
        let primary = Semantics.border
        let light = Semantics.borderLight
        let dark = Semantics.borderDark
    }

    struct Shadow {
        let small = Semantics.shadow
        let medium = Semantics.shadow
        let large = Semantics.shadow
    }

    let text = Text()
    let background = Background()
    let accent = Accent()
    let interactive = Interactive()
    let border = Border()
    let shadow = Shadow()
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
