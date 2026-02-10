import SwiftUI

#Preview("AutocompletionText - Default") {
    ZStack {
        Color.black.opacity(0.3)

        AutocompletionText(
            inputText: "trans",
            completion: "late to spanish",
            fontSize: 16,
            alignment: .topLeading,
            verticalPadding: 8
        )
    }
    .frame(width: 300, height: 100)
}

#Preview("AutocompletionText - Large") {
    ZStack {
        Color.black.opacity(0.8)
        AutocompletionText(
            inputText: "make ",
            completion: "it professional",
            fontSize: 20,
            alignment: .topLeading,
            verticalPadding: 12
        )
    }
    .frame(width: 400, height: 120)
}

#Preview("AutocompletionText - Long Text") {
    ZStack {
        Color.black.opacity(0.8)

        AutocompletionText(
            inputText: "convert to ",
            completion: "python code with error handling",
            fontSize: 16,
            alignment: .topLeading,
            verticalPadding: 8
        )
    }
    .frame(width: 350, height: 100)
}
