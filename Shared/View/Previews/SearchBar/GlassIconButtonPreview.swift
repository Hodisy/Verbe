import SwiftUI

#Preview("GlassIconButton - Default") {
    ZStack {
        Color.black.opacity(0.8)

        GlassIconButton(
            icon: "magnifyingglass",
            onTap: {}
        )
    }
    .frame(width: 200, height: 200)
}

#Preview("GlassIconButton - Bouncing") {
    ZStack {
        Color.black.opacity(0.8)

        GlassIconButton(
            icon: "sparkles",
            isBouncing: true,
            onTap: {}
        )
    }
    .frame(width: 200, height: 200)
}

#Preview("GlassIconButton - Custom Size") {
    ZStack {
        Color.black.opacity(0.8)

        GlassIconButton(
            icon: "ellipsis",
            size: 64,
            iconSize: 28,
            iconColor: .blue,
            onTap: {}
        )
    }
    .frame(width: 200, height: 200)
}
