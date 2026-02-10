import SwiftUI

#Preview("SearchBar") {
    @Previewable @State var state = SearchBarLogic(suggestions: [
        SearchSuggestion("Translate", icon: "translate"),
        SearchSuggestion("Translate to Spanish", icon: "globe.americas"),
        SearchSuggestion("Translate to French", icon: "globe.europe.africa"),
        SearchSuggestion("Professional Email", icon: "envelope"),
        SearchSuggestion("Proofread", icon: "checkmark.circle"),
        SearchSuggestion("Summarize", icon: "text.justify.left"),
        SearchSuggestion("Python Code", icon: "chevron.left.forwardslash.chevron.right"),
        SearchSuggestion("JavaScript Code", icon: "curlybraces"),
        SearchSuggestion("Fix Grammar", icon: "textformat.abc"),
    ])

    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        SearchBarView(state: state)
    }
    .frame(width: 800, height: 400)
}
