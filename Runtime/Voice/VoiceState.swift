import SwiftUI

// MARK: - Voice Mode

public enum VoiceMode: Equatable {
    case none           // No voice mode active
    case command        // fn hold → one-shot voice command
    case live           // fn + shift hold → bidirectional conversation
}

// MARK: - Voice Processing State

public enum VoiceProcessingState: Equatable {
    case idle           // Not recording
    case recording      // Actively recording audio
    case processing     // Sending to Gemini, waiting for response
    case completed      // Response received
}

// MARK: - Live Agent Status

public enum LiveAgentStatus: Equatable {
    case off            // Not connected
    case connecting     // WebSocket connecting
    case listening      // AI is listening to user
    case speaking       // AI is speaking
    case processing     // AI is processing/thinking
    case completed      // Session completed
}

// MARK: - Voice State (Observable)

@Observable
public final class VoiceState {
    // Current voice mode
    public var mode: VoiceMode = .none

    // Processing state
    public var processingState: VoiceProcessingState = .idle

    // Live mode status
    public var liveStatus: LiveAgentStatus = .off

    // Audio visualization data (0-255 levels)
    public var visualizerData: [Float] = []

    // Result from voice command
    public var draftResult: VoiceDraftResult?

    // Error message if any
    public var errorMessage: String?

    // Whether error requires opening system settings
    public var needsPermissionSettings = false

    // Recording duration (for UI display)
    public var recordingDuration: TimeInterval = 0

    // Whether the voice UI should be shown
    public var isVoiceUIVisible: Bool {
        mode != .none || processingState == .processing || processingState == .completed
    }

    // Whether actively recording
    public var isRecording: Bool {
        processingState == .recording
    }

    // Whether in live conversation mode
    public var isLiveMode: Bool {
        mode == .live
    }

    public init() {}

    // MARK: - Actions

    public func startRecording(mode: VoiceMode) {
        self.mode = mode
        self.processingState = .recording
        self.errorMessage = nil
        self.needsPermissionSettings = false
        self.draftResult = nil
        self.recordingDuration = 0

        if mode == .live {
            liveStatus = .connecting
        }
    }

    public func stopRecording() {
        if mode == .command {
            processingState = .processing
        } else if mode == .live {
            // Live mode: disconnect
            processingState = .idle
            liveStatus = .off
            mode = .none
        }
    }

    public func setResult(_ result: VoiceDraftResult) {
        self.draftResult = result
        self.processingState = .completed
    }

    public func setError(_ message: String, needsPermissionSettings: Bool = false) {
        self.errorMessage = message
        self.needsPermissionSettings = needsPermissionSettings
        self.processingState = .idle
        // Keep mode active briefly so badge can show the error
        // Mode will be reset when user releases key or taps to dismiss
        self.liveStatus = .off
    }

    public func reset() {
        mode = .none
        processingState = .idle
        liveStatus = .off
        visualizerData = []
        draftResult = nil
        errorMessage = nil
        needsPermissionSettings = false
        recordingDuration = 0
    }

    public func updateVisualizerData(_ data: [Float]) {
        self.visualizerData = data
    }

    public func updateLiveStatus(_ status: LiveAgentStatus) {
        self.liveStatus = status
        if status == .completed {
            processingState = .completed
        }
    }
}
