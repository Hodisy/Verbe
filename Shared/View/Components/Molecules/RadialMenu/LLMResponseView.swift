import SwiftUI
import AppKit

// MARK: - LLM Response State

@Observable
public final class LLMResponseState {
    public var responseText: String = ""
    public var isStreaming: Bool = false
    public var triggeredRecipe: Recipe?

    // Image support
    public var generatedImage: NSImage?
    public var isGeneratingImage: Bool = false
    public var imageGenerationProgress: String = ""

    public init() {}

    public func reset() {
        responseText = ""
        isStreaming = false
        triggeredRecipe = nil
        generatedImage = nil
        isGeneratingImage = false
        imageGenerationProgress = ""
    }
}

// MARK: - LLM Response View

public struct LLMResponseView: View {
    public let state: LLMResponseState
    public let onInsert: () -> Void
    public let onCopy: () -> Void
    public let onClose: () -> Void

    public init(
        state: LLMResponseState,
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
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill((state.triggeredRecipe?.color ?? .purple).opacity(0.12))
                        .overlay(
                            Circle()
                                .stroke((state.triggeredRecipe?.color ?? .purple).opacity(0.25), lineWidth: 0.6)
                        )
                    Image(systemName: state.triggeredRecipe?.icon ?? "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(state.triggeredRecipe?.color ?? .purple)
                }
                .frame(width: 24, height: 24)
                .glassEffect()

                Text(state.triggeredRecipe?.label ?? "Processing")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(nsColor: .labelColor).opacity(0.8))

                Spacer()
            }

            // Content: Image or Text
            if let generatedImage = state.generatedImage {
                // Display generated image
                Image(nsImage: generatedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if state.isGeneratingImage {
                // Image generation in progress
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(state.triggeredRecipe?.color ?? .purple)

                    Text(state.imageGenerationProgress.isEmpty ? "Generating image..." : state.imageGenerationProgress)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(nsColor: .labelColor).opacity(0.6))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Text response
                HStack(alignment: .bottom, spacing: 0) {
                    Text(state.responseText)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(nsColor: .labelColor).opacity(0.82))
                        .lineSpacing(3)
                        .textSelection(.enabled)

                    if state.isStreaming {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.75), .white.opacity(0.35)],
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
            }

            // Action buttons
            if !state.isStreaming && !state.isGeneratingImage && (!state.responseText.isEmpty || state.generatedImage != nil) {
                HStack(spacing: 6) {
                    Spacer()
                    if state.generatedImage == nil {
                        GlassActionIconButton(icon: "arrow.turn.down.left", action: onInsert)
                    }
                    GlassActionIconButton(icon: "doc.on.doc", action: onCopy)
                    GlassActionIconButton(icon: "xmark", action: onClose)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(14)
        .frame(width: state.generatedImage != nil ? 440 : 640)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
        .animation(.spring(response: 0.3), value: state.generatedImage != nil)
    }
}

private struct GlassActionIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(nsColor: .labelColor).opacity(0.8))
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(in: Circle())
    }
}
