//import SwiftUI
//
//struct ButtonThemeStyle: ButtonStyle {
//    let variant: ButtonVariant
//    let size: ButtonSize
//    let shape: ButtonShape
//    let state: ButtonState
//    let colorStyle: ButtonColorStyle
//    let textColor: Color?
//    let iconColor: Color?
//    let iconPlacement: ButtonIcon
//    let icon: Image?
//
//    func makeBody(configuration: Configuration) -> some View {
//        HStack(spacing: Spacing.xs) {
//            // Leading icon
//            if iconPlacement == .leading, let icon = icon {
//                icon.iconImageStyle(size.iconVariant, color: iconColor ?? textColor)
//            }
//
//            // Label (unless icon-only)
//            if iconPlacement != .only {
//                configuration.label
//                    .textStyle(size.textStyle, color: textColorRole())
//            }
//
//            // Trailing icon
//            if iconPlacement == .trailing, let icon = icon {
//                icon.iconImageStyle(size.iconVariant, color: iconColor ?? textColor)
//            }
//        }
//        .padding(size.padding)
//        .frame(maxWidth: size.isBlock ? .infinity : nil, minHeight: size.height)
//        .background(background(for: configuration))
//        .clipShape(shape == .pill ? Capsule() : RoundedRectangle(cornerRadius: Radius.md))
//        .opacity(state == .disabled ? 0.5 : 1.0)
//        .overlay(state == .loading ? ProgressView().progressViewStyle(CircularProgressViewStyle(tint: textColor)) : nil)
//        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
//        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
//    }
//
//    // MARK: - Helpers
//
//    private func background(for configuration: Configuration) -> some View {
//        Group {
//            switch colorStyle {
//            case .default:
//                variantBackground()
//            case .gradient:
//                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
//            case .gradientDuotone:
//                LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
//            case .gradientOutline:
//                RoundedRectangle(cornerRadius: Radius.md)
//                    .strokeBorder(LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
//            case .coloredShadow:
//                (variantBackground() as? Color ?? .blue)
//                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
//            }
//        }
//        .opacity(configuration.isPressed ? 0.85 : 1.0)
//    }
//
//    private func variantBackground() -> some ShapeStyle {
//        switch variant {
//        case .primary: return Color.accentColor
//        case .secondary: return Color.gray.opacity(0.2)
//        case .outline, .ghost, .text: return Color.clear
//        }
//    }
//
//    private func textColorRole() -> TextColorRole {
//        switch variant {
//        case .primary: return .inverse
//        case .secondary, .outline, .ghost, .text: return .primary
//        }
//    }
//}
//
//extension View {
//    func buttonThemeStyle(
//        variant: ButtonVariant,
//        size: ButtonSize = .medium,
//        shape: ButtonShape = .default,
//        state: ButtonState = .enabled,
//        colorStyle: ButtonColorStyle = .default,
//        textColor: Color? = nil,
//        iconColor: Color? = nil,
//        iconPlacement: ButtonIcon = .none,
//        icon: Image? = nil
//    ) -> some View {
//        buttonStyle(
//            ButtonThemeStyle(
//                variant: variant,
//                size: size,
//                shape: shape,
//                state: state,
//                colorStyle: colorStyle,
//                textColor: textColor,
//                iconColor: iconColor,
//                iconPlacement: iconPlacement,
//                icon: icon
//            )
//        )
//    }
//}
