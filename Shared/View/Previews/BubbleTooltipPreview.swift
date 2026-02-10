import SwiftUI

#Preview("BubbleTooltip - Single") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        BubbleTooltip(label: "Mailer")
    }
}

#Preview("BubbleTooltip - Various Labels") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack(spacing: 24) {
            BubbleTooltip(label: "Mailer")
            BubbleTooltip(label: "Tonify")
            BubbleTooltip(label: "Summarizer")
            BubbleTooltip(label: "Outliner")
            BubbleTooltip(label: "Long Recipe Name")
        }
    }
}

#Preview("BubbleTooltip - With Bubble") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "envelope")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

            BubbleTooltip(label: "Mailer")
        }
    }
}
