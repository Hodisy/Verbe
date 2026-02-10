enum ButtonVariant {
    case primary // main CTA (filled, strong contrast)
    case secondary // less emphasis (subtle background)
    case outline // border only
    case ghost // transparent - hover feedback
    case text // plain text - no background
}

/// Forme du bouton
enum ButtonShape {
    case `default` // rounded corners (Radius.md)
    case pill // fully rounded capsule
}

/// État du bouton
enum ButtonState {
    case enabled
    case disabled
    case loading
}

/// Style colorimétrique (effet visuel, pas la teinte)
enum ButtonColorStyle {
    case `default` // solid background or border
    case gradient // single gradient fill
    case gradientDuotone // two-color gradient
    case gradientOutline // gradient border
    case coloredShadow // accent shadow
}
