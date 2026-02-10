import SwiftUI

// MARK: - LLM Response State

@Observable
public final class LLMResponseStateOld {
    public var responseText: String = ""
    public var isStreaming: Bool = false
    public var triggeredRecipe: Recipe?

    public init() {}
}

// MARK: - LLM Response View

public struct LLMResponseViewOld: View {
    public let state: LLMResponseStateOld
    public let onInsert: () -> Void
    public let onCopy: () -> Void
    public let onClose: () -> Void

    public init(
        state: LLMResponseStateOld,
        onInsert: @escaping () -> Void,
        onCopy: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.state = state
        self.onInsert = onInsert
        self.onCopy = onCopy
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                // Tool icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(state.triggeredRecipe?.color.opacity(0.2) ?? Color.purple.opacity(0.2))
                    Image(systemName: state.triggeredRecipe?.icon ?? "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(state.triggeredRecipe?.color ?? .purple)
                }
                .frame(width: 28, height: 28)

                Text(state.triggeredRecipe?.label ?? "Processing")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(white: 0.15).opacity(0.8))

                Spacer()

                // Status indicator
                Circle()
                    .fill(state.isStreaming ? Color.purple.opacity(0.6) : Color.green.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: state.isStreaming)
            }

            // Content
            HStack(alignment: .bottom, spacing: 0) {
                Text(state.responseText)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.1).opacity(0.85))
                    .lineSpacing(4)

                // Blinking cursor
                if state.isStreaming {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 16)
                        .opacity(state.isStreaming ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: state.isStreaming)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Actions (show when done)
            if !state.isStreaming && !state.responseText.isEmpty {
                HStack(spacing: 4) {
                    Spacer()

                    // Insert button
                    Button(action: onInsert) {
                        HStack(spacing: 4) {
                            Image(systemName: "return")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Insert")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.85), Color.blue.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // Copy button
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(white: 0.35))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                    // Close button
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(white: 0.35))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.7), .white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 30, y: 10)
    }
}
