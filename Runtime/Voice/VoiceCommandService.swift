import Foundation

// MARK: - Voice Command Service (One-shot Voice Processing)

final class VoiceCommandService {
    private static let voiceCommandPromptKey = "voice_command_prompt"
    private static let defaultVoiceCommandPrompt = """
    You are a precise command-to-text drafting engine.

    Rules:
    1. Analyze the audio command.
    2. If "Selected Text" exists, perform an EDIT on it (rewrite, translate, etc.).
    3. If no "Selected Text", perform a CREATE action (write new message).
    4. You MUST NOT ask questions. Make the best reasonable default assumptions (e.g., neutral tone if unspecified, short length).
    5. If critical info is missing (like a time), use a placeholder like "[time]".
    6. Output JSON with the 'intent' details and the final 'form' text.
    """

    private var audioRecorder: AudioRecorder?
    private var recordingURL: URL?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?

    private var onVisualizerUpdate: (([Float]) -> Void)?
    private var onDurationUpdate: ((TimeInterval) -> Void)?
    private var onComplete: ((Result<VoiceDraftResult, Error>) -> Void)?

    private var context: UserContext?

    struct UserContext {
        let userName: String
        let targetApp: String
        let selectedText: String
    }

    // MARK: - Start Recording

    func startRecording(
        context: UserContext,
        onVisualizerUpdate: @escaping ([Float]) -> Void,
        onDurationUpdate: @escaping (TimeInterval) -> Void
    ) throws {
        self.context = context
        self.onVisualizerUpdate = onVisualizerUpdate
        self.onDurationUpdate = onDurationUpdate

        audioRecorder = AudioRecorder()

        recordingURL = try audioRecorder?.startRecordingToFile(onVisualizerUpdate: { [weak self] levels in
            DispatchQueue.main.async {
                self?.onVisualizerUpdate?(levels)
            }
        })

        // Start duration timer
        recordingStartTime = Date()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let startTime = self?.recordingStartTime else { return }
            let duration = Date().timeIntervalSince(startTime)
            self?.onDurationUpdate?(duration)
        }
    }

    // MARK: - Stop Recording & Process

    func stopRecordingAndProcess(
        completion: @escaping (Result<VoiceDraftResult, Error>) -> Void
    ) {
        print("🎤 [VoiceCommandService] Stopping recording and processing...")
        self.onComplete = completion

        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Stop recording
        guard let fileURL = audioRecorder?.stopRecordingToFile() else {
            print("❌ [VoiceCommandService] Recording failed - no file URL")
            completion(.failure(VoiceCommandError.recordingFailed))
            return
        }

        // Read audio file
        guard let audioData = try? Data(contentsOf: fileURL) else {
            print("❌ [VoiceCommandService] Failed to read audio file")
            completion(.failure(VoiceCommandError.audioReadFailed))
            return
        }

        print("🎤 [VoiceCommandService] Audio data loaded: \(audioData.count) bytes")

        // Clean up recording
        audioRecorder = nil

        // Process with Gemini
        print("🎤 [VoiceCommandService] Sending to Gemini...")
        processAudioWithGemini(audioData: audioData, mimeType: "audio/mp4")
    }

    // MARK: - Cancel

    func cancel() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        _ = audioRecorder?.stopRecordingToFile()
        audioRecorder = nil
        onComplete = nil
    }

    // MARK: - Private

    private func processAudioWithGemini(audioData: Data, mimeType: String) {
        guard let context = context else {
            onComplete?(.failure(VoiceCommandError.missingContext))
            return
        }

        let systemPrompt = buildSystemPrompt(context: context)

        GeminiService.shared.processAudioCommand(
            audioData: audioData,
            mimeType: mimeType,
            systemPrompt: systemPrompt
        ) { [weak self] result in
            self?.onComplete?(result)
            self?.cleanup()
        }
    }
    

    private func buildSystemPrompt(context: UserContext) -> String {
        let customOrDefaultPrompt = resolveVoiceCommandPrompt()

        return """
        Context:
        - User Name: \(context.userName)
        - Target App: \(context.targetApp)
        - Selected Text: "\(context.selectedText.isEmpty ? "(None)" : context.selectedText)"

        \(customOrDefaultPrompt)
        """
    }

    private func resolveVoiceCommandPrompt() -> String {
        let prompt = UserDefaults.standard.string(forKey: Self.voiceCommandPromptKey) ?? ""
        return prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.defaultVoiceCommandPrompt : prompt
    }

    private func cleanup() {
        // Delete temporary audio file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        context = nil
    }
}

// MARK: - Errors

enum VoiceCommandError: LocalizedError {
    case recordingFailed
    case audioReadFailed
    case missingContext
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .recordingFailed: return "Failed to record audio"
        case .audioReadFailed: return "Failed to read audio file"
        case .missingContext: return "Missing user context"
        case .processingFailed: return "Failed to process voice command"
        }
    }
}
