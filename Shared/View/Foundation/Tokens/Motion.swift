import SwiftUI

enum Motion {
    static let instant: Double = 0.0
    static let fast: Double = 0.15
    static let medium: Double = 0.25
    static let slow: Double = 0.35

    static let easeIn: Animation = .easeIn(duration: medium)
    static let easeOut: Animation = .easeOut(duration: medium)
    static let easeInOut: Animation = .easeInOut(duration: medium)
    static let spring: Animation = .spring(response: 0.4, dampingFraction: 0.8)
}
