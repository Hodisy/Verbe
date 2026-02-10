import SwiftUI

/// Horizontal row of suggestion badges
struct SuggestionBadgesRow: View {
    let suggestions: [SearchSuggestion]
    let onSelect: (SearchSuggestion) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(suggestions) { suggestion in
                SuggestionBadge(label: suggestion.label) {
                    onSelect(suggestion)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.leading, 60)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
