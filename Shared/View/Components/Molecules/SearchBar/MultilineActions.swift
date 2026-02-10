import SwiftUI

/// Action buttons for multiline search mode (waveform + send)
struct MultilineActions: View {
    let onRecordTap: () -> Void
    let onSendTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onRecordTap) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(nsColor: .secondaryLabelColor))
            }
            .buttonStyle(.plain)

            Button(action: onSendTap) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(nsColor: .controlTextColor))
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }
}
