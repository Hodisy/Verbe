import SwiftUI

/// Composite search input with text field, autocompletion, placeholder, and actions
struct SearchInputField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    let autocompletion: String?
    let showPlaceholder: Bool
    let isMultiline: Bool
    let glassID: String
    let namespace: Namespace.ID

    let onTab: () -> Void
    let onSendViaReturn: () -> Void
    let onSendViaButton: () -> Void
    let onResetTabState: () -> Void
    let onRecordTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if let completion = autocompletion, !completion.isEmpty {
                    AutocompletionText(
                        inputText: text,
                        completion: completion,
                        fontSize: isMultiline ? 16 : 24,
                        alignment: isMultiline ? .topLeading : .leading,
                        verticalPadding: isMultiline ? 12 : 0,
                    )
                }

                SearchTextField(
                    text: $text,
                    isFocused: $isFocused,
                    isMultiline: isMultiline,
                    fontSize: isMultiline ? 16 : 24,
                    alignment: isMultiline ? .topLeading : .leading,
                    verticalPadding: isMultiline ? 12 : 0,
                    trailingPadding: 0,
                    onTab: onTab,
                    onSendViaReturn: onSendViaReturn,
                    onResetTabState: onResetTabState
                )

                if showPlaceholder {
                    PlaceholderText(
                        text: "Search recipes...",
                        fontSize: isMultiline ? 16 : 24,
                        alignment: isMultiline ? .topLeading : .leading,
                        verticalPadding: isMultiline ? 12 : 0,
                    )
                }
            }

            if isMultiline {
                HStack {
                    Spacer()
                    MultilineActions(
                        onRecordTap: onRecordTap,
                        onSendTap: onSendViaButton
                    )
                }
            }
        }
        .frame(width: isMultiline ? 420 : 360)
        .frame(
            minHeight: 48,
            maxHeight: isMultiline ? 200 : 48
        )
        .glassEffect(in: RoundedRectangle(cornerRadius: isMultiline ? 16 : 24))
        .glassEffectID(glassID, in: namespace)
    }
}
