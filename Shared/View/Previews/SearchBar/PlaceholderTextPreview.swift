import SwiftUI

#Preview("PlaceholderText - Default") {
    ZStack {
        Color.black.opacity(0.8)

        PlaceholderText(
            text: "Type a recipe or prompt...",
            fontSize: 16,
            alignment: .topLeading,
            verticalPadding: 8
        )
    }
    .frame(width: 300, height: 100)
}

#Preview("PlaceholderText - Large") {
    ZStack {
        Color.black.opacity(0.8)

        PlaceholderText(
            text: "Search recipes",
            fontSize: 20,
            alignment: .topLeading,
            verticalPadding: 12
        )
    }
    .frame(width: 300, height: 100)
}

#Preview("PlaceholderText - Centered") {
    ZStack {
        Color.black.opacity(0.8)

        PlaceholderText(
            text: "Start typing...",
            fontSize: 18,
            alignment: .center,
            verticalPadding: 10
        )
    }
    .frame(width: 300, height: 100)
}
