import SwiftUI

// MARK: - Scroll Event Handler

private struct ScrollEventHandler: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context _: Context) -> ScrollCaptureView {
        let view = ScrollCaptureView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollCaptureView, context _: Context) {
        nsView.onScroll = onScroll
    }
}

private final class ScrollCaptureView: NSView {
    var onScroll: ((CGFloat) -> Void)?
    private var scrollMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil && scrollMonitor == nil {
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.onScroll?(event.scrollingDeltaY)
                return event
            }
        }
    }

    override func removeFromSuperview() {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
        super.removeFromSuperview()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil // Pass all events through to views below
    }
}

// MARK: - Previews

#Preview("Radial Menu - 3 Bubbles") {
    let recipes = [
        Recipe(icon: "flag", label: "Translate to French", systemPrompt: "Translate to French.", color: Color(red: 0.95, green: 0.36, blue: 0.36), glow: Color(red: 0.95, green: 0.36, blue: 0.36)),
        Recipe(icon: "globe.asia.australia", label: "Translate to Japanese", systemPrompt: "Translate to Japanese.", color: Color(red: 0.96, green: 0.2, blue: 0.4), glow: Color(red: 0.96, green: 0.2, blue: 0.4)),
        Recipe(icon: "globe.europe.africa", label: "Translate to English", systemPrompt: "Translate to English.", color: Color(red: 0.25, green: 0.5, blue: 0.95), glow: Color(red: 0.25, green: 0.5, blue: 0.95)),
        Recipe(icon: "envelope", label: "Mailer", systemPrompt: "You are a professional email writer. Transform the user's text into a well-structured, professional email. Keep it concise and include a clear call-to-action.", color: Color(red: 0.5, green: 0.53, blue: 0.97), glow: Color(red: 0.39, green: 0.4, blue: 0.95)),
        Recipe(icon: "textformat", label: "Tonify", systemPrompt: "You are a tone adjuster. Transform the user's text to be more conversational, friendly, and engaging while preserving the original meaning.", color: Color(red: 0.13, green: 0.83, blue: 0.93), glow: Color(red: 0.13, green: 0.83, blue: 0.93)),
        Recipe(icon: "doc.text", label: "Summarizer", systemPrompt: "You are a text summarizer. Provide a concise summary of the key points from the user's text. Use bullet points for clarity.", color: Color(red: 0.98, green: 0.75, blue: 0.14), glow: Color(red: 0.98, green: 0.75, blue: 0.14)),
        Recipe(icon: "list.bullet.indent", label: "Outliner", systemPrompt: "You are an outline creator. Structure the user's text into a clear outline with sections and bullet points.", color: Color(red: 0.38, green: 0.65, blue: 0.98), glow: Color(red: 0.38, green: 0.65, blue: 0.98)),
        Recipe(icon: "megaphone", label: "Marketer", systemPrompt: "You are a marketing copywriter. Transform the user's text into compelling marketing copy with power words and urgency.", color: Color(red: 0.91, green: 0.47, blue: 0.98), glow: Color(red: 0.91, green: 0.47, blue: 0.98)),
        Recipe(icon: "graduationcap", label: "Explainify", systemPrompt: "You are an expert explainer. Break down the user's text into simple, easy-to-understand language using analogies and examples.", color: Color(red: 0.64, green: 0.9, blue: 0.21), glow: Color(red: 0.64, green: 0.9, blue: 0.21)),
        Recipe(icon: "sparkles", label: "Creatify", systemPrompt: "You are a creative writer. Reimagine the user's text with fresh perspective, vivid imagery, and creative metaphors.", color: Color(red: 0.75, green: 0.52, blue: 0.99), glow: Color(red: 0.75, green: 0.52, blue: 0.99)),
        Recipe(icon: "number", label: "Datify", systemPrompt: "You are a data analyst. Analyze the user's text and provide data-driven insights, metrics, or structured analysis.", color: Color(red: 0.58, green: 0.64, blue: 0.72), glow: Color(red: 0.58, green: 0.64, blue: 0.72)),
    ]

    let state = RadialMenuState(recipes: recipes, maxBubbles: 3)

    return ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        RadialMenuView(
            state: state,
            onRecipeSelected: { recipe in
                print("Selected recipe: \(recipe.label)")
            },
            onSearchSelected: {
                print("Search selected")
            }
        )
        .frame(width: 400, height: 400)

        ScrollEventHandler { delta in
            state.scroll(delta: delta)
        }
    }
}
