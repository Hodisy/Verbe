import SwiftUI

/// Container view with macOS 26+ liquid glass material effect
/// Provides a modern glass morphism background with blur and vibrancy
public struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    public init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        content
            .padding(spacing)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            }
    }
}
