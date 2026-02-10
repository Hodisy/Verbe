import SwiftUI

struct SearchTextField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isMultiline: Bool
    let fontSize: CGFloat
    let alignment: Alignment
    let verticalPadding: CGFloat
    let trailingPadding: CGFloat
    let onTab: () -> Void
    let onSendViaReturn: () -> Void
    let onResetTabState: () -> Void

    var body: some View {
        TextField("", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(isMultiline ? 3 ... 10 : 1 ... 1)
            .disableAutocorrection(true)
            .focused($isFocused)
            .foregroundStyle(Color(nsColor: .labelColor))
            .tint(Color(nsColor: .labelColor))
            .font(.system(size: fontSize))
            .padding(.horizontal, 12)
            .padding(.vertical, verticalPadding)
            .padding(.trailing, trailingPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .onKeyPress(.tab) {
                onTab()
                return .handled
            }
            .onKeyPress(.return, phases: .down) { keyPress in
                if isMultiline {
                    if keyPress.modifiers.contains(.shift) {
                        onSendViaReturn()
                        return .handled
                    }
                    text += "\n"
                    return .handled
                } else {
                    onSendViaReturn()
                    return .handled
                }
            }
            .onKeyPress { keyPress in
                if keyPress.characters == "\u{7F}" && text.isEmpty {
                    onResetTabState()
                    return .handled
                }

                if keyPress.key == .escape {
                    onResetTabState()
                    return .handled
                }

                return .ignored
            }
    }
}
