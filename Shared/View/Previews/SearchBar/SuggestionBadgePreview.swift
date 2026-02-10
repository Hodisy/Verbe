import SwiftUI

#Preview("SuggestionBadge - Single") {
    ZStack {
        Color.black.opacity(0.8)

        SuggestionBadge(
            label: "Professional",
            onTap: {}
        )
    }
    .frame(width: 200, height: 100)
}

#Preview("SuggestionBadge - Multiple") {
    ZStack {
        Color.black.opacity(0.8)

        HStack(spacing: 8) {
            SuggestionBadge(label: "Spanish", onTap: {})
            SuggestionBadge(label: "Professional", onTap: {})
            SuggestionBadge(label: "Code", onTap: {})
        }
    }
    .frame(width: 400, height: 100)
}

#Preview("SuggestionBadge - Long Label") {
    ZStack {
        Color.black.opacity(0.8)

        SuggestionBadge(
            label: "Translate to Spanish",
            onTap: {}
        )
    }
    .frame(width: 300, height: 100)
}
