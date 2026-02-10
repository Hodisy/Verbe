
import SwiftUI

enum Semantics {
    // Primary colors - Modern purple/indigo inspired by Raycast
    static let primary = Color(red: 0.45, green: 0.33, blue: 0.91)        // #7254E8
    static let primaryLight = Color(red: 0.58, green: 0.47, blue: 0.94)   // #9478F0
    static let primaryDark = Color(red: 0.35, green: 0.24, blue: 0.75)    // #593DBF
    static let primaryBackground = Color(red: 0.95, green: 0.94, blue: 0.99)
    static let primaryForeground = Color.white

    // Secondary colors - Vibrant cyan/blue
    static let secondary = Color(red: 0.0, green: 0.71, blue: 0.97)       // #00B5F7
    static let secondaryLight = Color(red: 0.2, green: 0.80, blue: 0.98)  // #33CCF9
    static let secondaryDark = Color(red: 0.0, green: 0.60, blue: 0.85)   // #0099D9
    static let secondaryBackground = Color(red: 0.92, green: 0.97, blue: 0.99)
    static let secondaryForeground = Color.white

    // Neutral colors - Refined grayscale
    static let neutral = Color(red: 0.56, green: 0.57, blue: 0.60)        // #8F9299
    static let neutralLight = Color(red: 0.82, green: 0.83, blue: 0.85)   // #D1D3D9
    static let neutralDark = Color(red: 0.28, green: 0.29, blue: 0.31)    // #474A4F
    static let neutralBackground = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let neutralForeground = Color(red: 0.15, green: 0.16, blue: 0.18)

    // Status colors - High contrast, accessible
    static let success = Color(red: 0.13, green: 0.80, blue: 0.47)        // #21CC77
    static let successBackground = Color(red: 0.92, green: 0.99, blue: 0.95)
    static let successForeground = Color(red: 0.09, green: 0.51, blue: 0.31)

    static let warning = Color(red: 1.0, green: 0.67, blue: 0.13)         // #FFAB21
    static let warningBackground = Color(red: 1.0, green: 0.97, blue: 0.92)
    static let warningForeground = Color(red: 0.72, green: 0.42, blue: 0.0)

    static let error = Color(red: 1.0, green: 0.31, blue: 0.29)           // #FF4F4A
    static let errorBackground = Color(red: 1.0, green: 0.95, blue: 0.95)
    static let errorForeground = Color(red: 0.85, green: 0.11, blue: 0.11)

    // Background colors - Clean, modern whites/grays
    static let background = Color(red: 0.99, green: 0.99, blue: 1.0)
    static let backgroundSecondary = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let backgroundTertiary = Color(red: 0.94, green: 0.95, blue: 0.96)

    // Text colors - High contrast for readability
    static let textPrimary = Color(red: 0.11, green: 0.12, blue: 0.14)    // #1C1D23
    static let textSecondary = Color(red: 0.44, green: 0.46, blue: 0.50)  // #707580
    static let textTertiary = Color(red: 0.64, green: 0.65, blue: 0.68)   // #A3A6AD
    static let textInverse = Color.white

    // Border colors - Subtle, refined
    static let border = Color(red: 0.88, green: 0.89, blue: 0.91)         // #E0E3E8
    static let borderLight = Color(red: 0.94, green: 0.95, blue: 0.96)    // #F0F1F3
    static let borderDark = Color(red: 0.74, green: 0.76, blue: 0.79)     // #BDC1C9

    // Interactive colors - Matches primary
    static let interactive = Color(red: 0.45, green: 0.33, blue: 0.91)    // Same as primary
    static let interactiveActive = Color(red: 0.35, green: 0.24, blue: 0.75)
    static let interactiveHover = Color(red: 0.58, green: 0.47, blue: 0.94)
    static let interactiveDisabled = Color(red: 0.82, green: 0.83, blue: 0.85)

    // Shadow colors - Subtle depth
    static let shadow = Color.black.opacity(0.08)
}
