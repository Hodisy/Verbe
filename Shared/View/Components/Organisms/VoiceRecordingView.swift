import SwiftUI

// MARK: - Voice Recording View

public struct VoiceRecordingView: View {
    public let state: VoiceState
    public let onClose: () -> Void

    public init(state: VoiceState, onClose: @escaping () -> Void) {
        self.state = state
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header with mode indicator
            HStack {
                // Mode badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.mode == .live ? Color.red : Color.orange)
                        .frame(width: 8, height: 8)
                        .opacity(state.isRecording ? 1 : 0.5)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: state.isRecording)

                    Text(state.mode == .live ? "LIVE" : "RECORDING")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(state.mode == .live ? Color.red : Color.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill((state.mode == .live ? Color.red : Color.orange).opacity(0.15))
                )

                Spacer()

                // Status indicator for live mode
                if state.mode == .live {
                    liveStatusBadge
                }

                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(nsColor: .labelColor).opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .glassEffect(in: Circle())
            }

            // Audio visualizer
            AudioVisualizerView(levels: state.visualizerData, isLiveMode: state.mode == .live)
                .frame(height: 60)

            // Duration or status text
            HStack {
                if state.processingState == .processing {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Processing...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(nsColor: .labelColor).opacity(0.7))
                } else if state.isRecording {
                    Text(formatDuration(state.recordingDuration))
                        .font(.system(size: 24, weight: .light).monospacedDigit())
                        .foregroundStyle(Color(nsColor: .labelColor).opacity(0.8))
                }
            }

            // Instructions
            Text(instructionText)
                .font(.system(size: 12))
                .foregroundStyle(Color(nsColor: .labelColor).opacity(0.5))
                .multilineTextAlignment(.center)

            // Error message if any
            if let error = state.errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red)

                    if state.needsPermissionSettings {
                        Button(action: openSystemSettings) {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                Text("Open System Settings")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .frame(width: 320)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 30, y: 10)
    }

    private var instructionText: String {
        switch state.mode {
        case .command:
            return "Release fn to process your voice command"
        case .live:
            return "Speak naturally. Release fn+shift to end."
        case .none:
            return ""
        }
    }

    @ViewBuilder
    private var liveStatusBadge: some View {
        HStack(spacing: 4) {
            switch state.liveStatus {
            case .connecting:
                ProgressView()
                    .scaleEffect(0.5)
                Text("Connecting")
            case .listening:
                Image(systemName: "ear")
                Text("Listening")
            case .speaking:
                Image(systemName: "waveform")
                Text("AI Speaking")
            case .processing:
                Image(systemName: "brain")
                Text("Thinking")
            case .completed:
                Image(systemName: "checkmark")
                Text("Done")
            case .off:
                EmptyView()
            }
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch state.liveStatus {
        case .connecting: return .yellow
        case .listening: return .green
        case .speaking: return .blue
        case .processing: return .purple
        case .completed: return .gray
        case .off: return .clear
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, milliseconds)
    }

    private func openSystemSettings() {
        // Open System Settings to Privacy & Security > Microphone
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Audio Visualizer View

struct AudioVisualizerView: View {
    let levels: [Float]
    let isLiveMode: Bool

    private let barCount = 16
    private let barSpacing: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    AudioBar(
                        level: normalizedLevel(at: index),
                        color: isLiveMode ? .red : .orange
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func normalizedLevel(at index: Int) -> CGFloat {
        guard !levels.isEmpty else { return 0.1 }

        // Map bar index to level array index
        let levelIndex = Int(Float(index) / Float(barCount) * Float(levels.count))
        let clampedIndex = min(levelIndex, levels.count - 1)

        // Get level and add minimum height
        let level = CGFloat(levels[clampedIndex])
        return max(0.1, min(1.0, level))
    }
}

struct AudioBar: View {
    let level: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.8), color.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(maxWidth: .infinity)
            .scaleEffect(y: level, anchor: .center)
            .animation(.easeOut(duration: 0.1), value: level)
    }
}
