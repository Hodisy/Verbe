import QuartzCore
import SwiftUI

// MARK: - Recipe Model

public struct Recipe: Identifiable, Codable {
    public let id: UUID
    public var icon: String
    public var label: String
    public var systemPrompt: String
    public var color: Color
    public var glow: Color
    public var isCustom: Bool
    public var isVisionRecipe: Bool
    public var isImageGenRecipe: Bool

    public init(
        id: UUID = UUID(),
        icon: String,
        label: String,
        systemPrompt: String,
        color: Color,
        glow: Color,
        isCustom: Bool = false,
        isVisionRecipe: Bool = false,
        isImageGenRecipe: Bool = false
    ) {
        self.id = id
        self.icon = icon
        self.label = label
        self.systemPrompt = systemPrompt
        self.color = color
        self.glow = glow
        self.isCustom = isCustom
        self.isVisionRecipe = isVisionRecipe
        self.isImageGenRecipe = isImageGenRecipe
    }

    // Custom Codable implementation for Color
    enum CodingKeys: String, CodingKey {
        case id, icon, label, systemPrompt, colorHex, glowHex, isCustom, isVisionRecipe, isImageGenRecipe
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        icon = try container.decode(String.self, forKey: .icon)
        label = try container.decode(String.self, forKey: .label)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        isCustom = try container.decode(Bool.self, forKey: .isCustom)
        isVisionRecipe = try container.decodeIfPresent(Bool.self, forKey: .isVisionRecipe) ?? false
        isImageGenRecipe = try container.decodeIfPresent(Bool.self, forKey: .isImageGenRecipe) ?? false

        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex) ?? .blue

        let glowHex = try container.decode(String.self, forKey: .glowHex)
        glow = Color(hex: glowHex) ?? color
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(icon, forKey: .icon)
        try container.encode(label, forKey: .label)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(isCustom, forKey: .isCustom)
        try container.encode(isVisionRecipe, forKey: .isVisionRecipe)
        try container.encode(isImageGenRecipe, forKey: .isImageGenRecipe)
        try container.encode(color.toHex(), forKey: .colorHex)
        try container.encode(glow.toHex(), forKey: .glowHex)
    }
}

// Color extensions for hex conversion
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#0000FF"
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Radial Menu State

@Observable
public final class RadialMenuState {
    public var hoveredIndex: Int?
    public var currentIndex: Double = 0
    public var maxBubbles: Int = 3
    public var recipes: [Recipe]
    public var isSearchExpanded: Bool = false
    public var searchText: String = ""

    // Geometry (set by container)
    public var menuCenter: CGPoint = .zero
    public var radius: CGFloat = 42 // Match JS: const radius = 56;

    // Mouse tracking (internal)
    private var mousePosition: CGPoint = .zero
    private var lastConfirmedIndex: Int?
    private var hoverConfirmationCount: Int = 0
    private let hysteresisThreshold: Int = 1 // Changed from 3 to 1 for instant response like CSS

    // Spring animation state (matches JS behavior)
    private var scrollVelocity: Double = 0
    private var targetIndex: Double = 0
    private var isSnapping: Bool = false
    private var displayLink: CADisplayLink?
    private var lastScrollTime: CFTimeInterval = 0
    private var scrollDebounceTimer: Timer?

    // Spring physics constants (from JS)
    private let springStiffness: Double = 0.15
    private let springDamping: Double = 0.75
    private let scrollSensitivity: Double = 0.004

    // Bubble angle division (1/6 = 60°, 1/7 ≈ 51.4°, 1/9 = 40°, 1/3 = 120°)
    private let bubbleAngleDivision: Double = 6.1

    public init(recipes: [Recipe], maxBubbles: Int = 3) {
        self.recipes = recipes
        self.maxBubbles = maxBubbles
    }

    deinit {
        stopAnimation()
        scrollDebounceTimer?.invalidate()
    }

    // MARK: - Recipe Management

    public func recipeAt(slot: Int) -> Recipe {
        let totalItems = recipes.count
        // Use targetIndex during snapping to prevent icon flickering (like JS contentIndex)
        let contentIndex = isSnapping ? Int(targetIndex.rounded()) : Int(currentIndex.rounded())
        var itemIndex = (slot + contentIndex) % totalItems
        if itemIndex < 0 { itemIndex += totalItems }
        return recipes[itemIndex]
    }

    // MARK: - Angle Calculation

    public func bubbleAngle(for slot: Int, offset: Double = 0) -> Double {
        let adjustedSlot = Double(slot) - offset
        // Configurable angle division: 2π / bubbleAngleDivision
        let angleStep = (2 * Double.pi) / bubbleAngleDivision

        // Target: center bubble at top-left (northwest = -3π/4 in SwiftUI coords)
        let targetAngle = -3 * Double.pi / 4

        // Calculate offset to center the middle bubble at targetAngle
        let middleSlot = Double(maxBubbles - 1) / 2.0
        let startAngle = targetAngle - (angleStep * middleSlot)

        return startAngle + angleStep * adjustedSlot
    }

    /// Fractional offset from snapped position (0 = perfectly snapped)
    public var positionOffset: Double {
        let contentIndex = isSnapping ? targetIndex : currentIndex.rounded()
        return currentIndex - contentIndex
    }

    /// Overall scroll intensity (0-1) for global effects
    public var scrollIntensity: Double {
        min(1, abs(positionOffset) * 2 + abs(scrollVelocity) * 3)
    }

    public func bubbleOffset(for slot: Int) -> CGSize {
        let angle = bubbleAngle(for: slot, offset: positionOffset)
        // Match JS exactly: const x = Math.cos(baseAngle) * radius; const y = Math.sin(baseAngle) * radius;
        // Both CSS and SwiftUI use positive Y going down in their local view coordinate systems
        return CGSize(
            width: CGFloat(cos(angle)) * radius,
            height: CGFloat(sin(angle)) * radius // Positive, same as JS
        )
    }

    /// Scale factor for a bubble (shrinks only when moving outside visible range)
    public func bubbleScale(for slot: Int) -> Double {
        // At rest (positionOffset = 0), all bubbles are full size
        // Only shrink when a bubble moves beyond its normal slot range

        // How far this bubble has moved from its home slot position
        let displacement = abs(positionOffset)

        // Only the bubbles at the edges (slot 0 and slot maxBubbles-1) should shrink
        // And only when they're moving "outward" (away from visible area)

        let isFirstSlot = slot == 0
        let isLastSlot = slot == maxBubbles - 1

        // Check if this bubble is moving toward the edge (about to disappear)
        let movingOutward: Bool
        if isFirstSlot {
            // First slot shrinks when scrolling makes it move "up/out"
            movingOutward = positionOffset > 0
        } else if isLastSlot {
            // Last slot shrinks when scrolling makes it move "down/out"
            movingOutward = positionOffset < 0
        } else {
            // Middle bubbles don't shrink
            movingOutward = false
        }

        var scale = 1.0

        if movingOutward {
            // Shrink based on how far we've scrolled (0 to 0.5 = full to small)
            let shrinkFactor = min(1, displacement * 2)
            scale = 1.0 - (shrinkFactor * 0.6)
        }

        // Global velocity shrink: all bubbles shrink slightly during fast scroll
        let velocityShrink = min(1, abs(scrollVelocity) * 3) * 0.15
        scale *= (1.0 - velocityShrink)

        return scale
    }

    /// Opacity for a bubble (fades slightly during scroll)
    public func bubbleOpacity(for slot: Int) -> Double {
        // Center bubbles stay bright, edge bubbles dim during scroll
        let centerDistance = abs(Double(slot) - Double(maxBubbles - 1) / 2)
        let maxDistance = Double(maxBubbles) / 2
        let edgeFactor = centerDistance / maxDistance

        // Base opacity during scroll
        let scrollFade = 1.0 - (edgeFactor * 0.25 * scrollIntensity)

        return max(0.7, scrollFade)
    }

    /// Blur radius for a bubble (subtle motion blur effect)
    public func bubbleBlur(for _: Int) -> Double {
        // Subtle blur only during fast scroll
        let velocityFactor = min(1, abs(scrollVelocity) * 4)

        // Max 2px blur, very subtle
        return velocityFactor * 2.0
    }

    /// Rotation angle for a bubble (subtle spin during scroll)
    public func bubbleRotation(for slot: Int) -> Double {
        // Rotate in scroll direction, more for edge bubbles
        let direction = scrollVelocity > 0 ? 1.0 : -1.0
        let intensity = min(1, abs(scrollVelocity) * 3)

        // Edge bubbles rotate more
        let centerDistance = abs(Double(slot) - Double(maxBubbles - 1) / 2)
        let rotationAmount = centerDistance * intensity * direction * 8 // Max 8 degrees

        return rotationAmount
    }

    // MARK: - Hover Detection (Fixed Algorithm)

    /// Update hover state with a point in the LOCAL coordinate space of the radial menu
    /// (0,0) = top-left of the menu view, not screen coordinates
    public func updateHover(at localPoint: CGPoint, in viewSize: CGSize) {
        // Calculate relative position from menu center
        let centerX = viewSize.width / 2
        let centerY = viewSize.height / 2

        let dx = localPoint.x - centerX
        let dy = localPoint.y - centerY

        mousePosition = CGPoint(x: dx, y: dy)

        let candidateIndex = calculateHoveredIndex(dx: dx, dy: dy)

        // Apply hysteresis
        if candidateIndex == lastConfirmedIndex {
            hoverConfirmationCount = 0
            return
        }

        hoverConfirmationCount += 1

        if hoverConfirmationCount >= hysteresisThreshold {
            lastConfirmedIndex = candidateIndex
            hoveredIndex = candidateIndex
            hoverConfirmationCount = 0
        }
    }

    private func calculateHoveredIndex(dx: CGFloat, dy: CGFloat) -> Int? {
        let distance = sqrt(dx * dx + dy * dy)

        // Center bubble (search)
        if distance < 25 {
            return -1
        }

        // No distance limit - track cursor position across entire screen
        // When far from center, just select the bubble in that direction

        // Calculate angle from center
        // atan2(y, x) returns angle in radians from -π to π
        // In SwiftUI views, Y grows downward (same as CSS), so use positive dy
        var mouseAngle = atan2(dy, dx)
        if mouseAngle < 0 { mouseAngle += .pi * 2 }

        var bestIndex: Int? = nil
        var bestDiff = Double.infinity

        for i in 0 ..< maxBubbles {
            var angle = bubbleAngle(for: i)
            if angle < 0 { angle += .pi * 2 }
            if angle > .pi * 2 { angle -= .pi * 2 }

            var diff = abs(mouseAngle - angle)
            diff = min(diff, .pi * 2 - diff)

            if diff < bestDiff {
                bestDiff = diff
                bestIndex = i
            }
        }

        // Only select if close enough to a bubble
        let threshold = Double.pi / Double(max(maxBubbles, 3))
        if bestDiff < threshold {
            return bestIndex
        }

        return nil
    }

    // MARK: - Scroll Management

    public func scroll(delta: CGFloat) {
        // Cancel any ongoing snap animation
        if isSnapping {
            stopAnimation()
            isSnapping = false
        }

        // Track scroll momentum
        let now = CACurrentMediaTime()
        let timeDelta = now - lastScrollTime
        lastScrollTime = now

        let scrollDelta = Double(delta) * scrollSensitivity

        // Accumulate velocity for momentum
        if timeDelta < 0.1 {
            // Quick successive scrolls - build up velocity
            scrollVelocity = scrollVelocity * 0.5 + scrollDelta * 0.8
        } else {
            // Fresh scroll - reset velocity
            scrollVelocity = scrollDelta
        }

        // Update current index
        currentIndex += scrollDelta

        // Wrap around for infinite scroll
        wrapCurrentIndex()

        // Debounce: after scrolling stops, snap to nearest slot
        scrollDebounceTimer?.invalidate()
        scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: false) { [weak self] _ in
            self?.snapToNearestSlot()
        }
    }

    private func wrapCurrentIndex() {
        let total = Double(recipes.count)
        while currentIndex < 0 {
            currentIndex += total
        }
        while currentIndex >= total {
            currentIndex -= total
        }
    }

    private func snapToNearestSlot() {
        let total = Double(recipes.count)

        // Keep some momentum for natural feel
        scrollVelocity *= 0.3

        // Round to nearest integer index
        targetIndex = (currentIndex + scrollVelocity * 5).rounded()

        // Wrap target index
        while targetIndex < 0 {
            targetIndex += total
        }
        while targetIndex >= total {
            targetIndex -= total
        }

        // Adjust currentIndex to avoid jumping across the wrap boundary
        let diff = targetIndex - currentIndex
        if diff > total / 2 {
            currentIndex += total
        } else if diff < -total / 2 {
            targetIndex += total
        }

        isSnapping = true
        startAnimation()
    }

    private func startAnimation() {
        stopAnimation()

        // Use a timer for cross-platform compatibility (CADisplayLink is iOS-only in some contexts)
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            if !self.isSnapping {
                timer.invalidate()
                return
            }

            self.animateSpring()
        }
    }

    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func animateSpring() {
        let threshold = 0.001
        let diff = targetIndex - currentIndex

        // Check if we're close enough AND velocity is low enough to stop
        if abs(diff) < threshold, abs(scrollVelocity) < threshold {
            currentIndex = targetIndex
            scrollVelocity = 0
            isSnapping = false
            wrapCurrentIndex()
            return
        }

        // Spring physics: F = -kx - cv (spring force - damping)
        let springForce = springStiffness * diff

        // Update velocity with spring force and apply damping
        scrollVelocity += springForce
        scrollVelocity *= (1 - springDamping * 0.3)
        currentIndex += scrollVelocity
    }

    // MARK: - Reset

    public func reset() {
        lastConfirmedIndex = nil
        hoverConfirmationCount = 0
        hoveredIndex = nil
        mousePosition = .zero
    }
}
