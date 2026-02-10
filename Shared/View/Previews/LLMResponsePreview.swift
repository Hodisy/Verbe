import SwiftUI

// MARK: - Scroll Event Handler

#Preview("LLM Response - Streaming") {
    let state = LLMResponseState()
    state.responseText = "I've drafted a professional email for you. The tone is warm yet"
    state.isStreaming = true
    state.triggeredRecipe = Recipe(
        icon: "envelope",
        label: "Mailer",
        systemPrompt: "You are a professional email writer. Transform the user's text into a well-structured, professional email. Keep it concise and include a clear call-to-action.",
        color: Color(red: 0.5, green: 0.53, blue: 0.97),
        glow: Color(red: 0.39, green: 0.4, blue: 0.95)
    )

   return ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        LLMResponseView(
            state: state,
            onInsert: { print("Insert") },
            onCopy: { print("Copy") },
            onClose: { print("Close") }
        )
    }
}

#Preview("LLM Response - Complete") {
    let state = LLMResponseState()
    state.responseText = "I've drafted a professional email for you. The tone is warm yet professional, with a clear call-to-action."
    state.isStreaming = false
    state.triggeredRecipe = Recipe(
        icon: "envelope",
        label: "Mailer",
        systemPrompt: "You are a professional email writer. Transform the user's text into a well-structured, professional email. Keep it concise and include a clear call-to-action.",
        color: Color(red: 0.5, green: 0.53, blue: 0.97),
        glow: Color(red: 0.39, green: 0.4, blue: 0.95)
    )

    return ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        LLMResponseView(
            state: state,
            onInsert: { print("Insert") },
            onCopy: { print("Copy") },
            onClose: { print("Close") }
        )
    }
}
