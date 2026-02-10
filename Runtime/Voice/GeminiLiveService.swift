import Foundation

// MARK: - Gemini Live Service (WebSocket Bidirectional Audio)

final class GeminiLiveService: NSObject {
    private static let liveVoicePromptKey = "live_voice_prompt"
    private static let defaultLiveVoicePrompt = """
    You are a professional drafting assistant.

    Rules:
    1. If "Selected Text" exists, assume EDIT flow (rewrite, fix, translate).
    2. If no "Selected Text", assume CREATE flow (write from scratch).
    3. Adapt your responses and the final draft to the format of the Target App (e.g., Slack=concise, Email=subject/body/signoff).
    4. Ask short clarifying questions if the request is ambiguous.
    5. Once you have enough info, call 'finalize_draft'.
    6. IMPORTANT: After calling 'finalize_draft', DO NOT STOP. Continue the conversation verbally. Tell the user you have created the draft and ask if they want any changes.
    7. If the user asks for changes, call 'finalize_draft' again with the updated version.
    8. If the user indicates they are satisfied, says "looks good", "thanks", or "goodbye", call 'close_session' to end the interaction.
    9. If the user asks you to generate, create, or draw an image, call 'generate_image' with a detailed prompt. Continue the conversation after calling it.
    """

    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var audioRecorder: AudioRecorder?
    private var audioPlayer: AudioPlayer?

    private var isConnected = false
    private var isDisconnecting = false
    private var callbacks: LiveServiceCallbacks?
    private var context: UserContext?

    private let model = "gemini-2.5-flash-native-audio-preview-12-2025"

    // MARK: - Callbacks

    struct LiveServiceCallbacks {
        let onVisualizerUpdate: ([Float]) -> Void
        let onDraftComplete: (VoiceDraftResult) -> Void
        let onImageRequest: (String) -> Void
        let onStatusChange: (LiveAgentStatus) -> Void
        let onDisconnect: () -> Void
        let onCloseIntent: () -> Void
        let onError: (Error) -> Void
    }

    // MARK: - Context

    struct UserContext {
        let userName: String
        let targetApp: String
        let selectedText: String
    }

    // MARK: - Connect

    func connect(context: UserContext, callbacks: LiveServiceCallbacks) {
        guard !isConnected else { return }

        self.context = context
        self.callbacks = callbacks

        callbacks.onStatusChange(.connecting)

        // Get API key
        guard let apiKey = getApiKey(), !apiKey.isEmpty else {
            callbacks.onError(GeminiError.missingApiKey)
            return
        }

        // Build WebSocket URL
        let endpoint = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
        guard var urlComponents = URLComponents(string: endpoint) else {
            callbacks.onError(GeminiError.invalidURL)
            return
        }

        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let url = urlComponents.url else {
            callbacks.onError(GeminiError.invalidURL)
            return
        }

        // Create WebSocket
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()

        // Send setup message
        sendSetupMessage()

        // Setup audio player for responses
        setupAudioPlayer()

        // Start listening for messages
        receiveMessage()
    }

    // MARK: - Disconnect

    func disconnect() {
        guard !isDisconnecting else { return }
        isDisconnecting = true
        isConnected = false

        // Capture callback before nilling to avoid re-entrant calls
        let onDisconnect = callbacks?.onDisconnect
        callbacks = nil
        context = nil

        // Capture all references before nilling instance vars
        let recorder = audioRecorder
        let player = audioPlayer
        let ws = webSocket
        let session = urlSession

        audioRecorder = nil
        audioPlayer = nil
        webSocket = nil
        urlSession = nil

        // Move ALL cleanup to background to avoid blocking the main thread.
        // AVAudioEngine.stop() can block if the engine is mid-render cycle.
        DispatchQueue.global(qos: .utility).async {
            recorder?.stopStreaming()
            player?.cleanup()
            ws?.cancel(with: .goingAway, reason: nil)
            session?.invalidateAndCancel()
        }

        onDisconnect?()
        isDisconnecting = false
    }

    // MARK: - Send Audio

    func sendAudioChunk(_ data: Data) {
        guard isConnected else { return }

        let base64Audio = data.base64EncodedString()

        let message: [String: Any] = [
            "realtimeInput": [
                "mediaChunks": [
                    [
                        "mimeType": "audio/pcm;rate=16000",
                        "data": base64Audio
                    ]
                ]
            ]
        ]

        sendJSON(message)
    }

    // MARK: - Private Methods

    private func getApiKey() -> String? {
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            return envKey
        }
        return UserDefaults.standard.string(forKey: "gemini_api_key")
    }

    private func sendSetupMessage() {
        guard let context = context else { return }
        let customOrDefaultPrompt = resolveLiveVoicePrompt()

        let systemInstruction = """
        Current Context:
        - User Name: \(context.userName)
        - Target App: \(context.targetApp)
        - Selected Text: "\(context.selectedText.isEmpty ? "(None)" : context.selectedText)"

        \(customOrDefaultPrompt)
        """

        let setupMessage: [String: Any] = [
            "setup": [
                "model": "models/\(model)",
                "generationConfig": [
                    "responseModalities": ["AUDIO"]
                ],
                "systemInstruction": [
                    "parts": [["text": systemInstruction]]
                ],
                "tools": [
                    [
                        "functionDeclarations": [
                            buildFinalizeDraftTool(),
                            buildCloseSessionTool(),
                            buildGenerateImageTool()
                        ]
                    ]
                ]
            ]
        ]

        sendJSON(setupMessage)
    }

    private func buildFinalizeDraftTool() -> [String: Any] {
        [
            "name": "finalize_draft",
            "description": "Call this function when you have sufficient information to generate the final text draft for the user.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "intent": [
                        "type": "OBJECT",
                        "description": "Structured representation of the user's intent.",
                        "properties": [
                            "mode": ["type": "STRING"],
                            "action": ["type": "STRING"],
                            "target_app": ["type": "STRING"],
                            "language": ["type": "STRING"],
                            "tone": ["type": "STRING"],
                            "instruction": ["type": "STRING"],
                            "input_text": ["type": "STRING"]
                        ],
                        "required": ["mode", "action", "target_app", "language", "tone", "instruction"]
                    ],
                    "form": [
                        "type": "STRING",
                        "description": "The final formatted text output ready to be sent/pasted."
                    ]
                ],
                "required": ["intent", "form"]
            ]
        ]
    }

    private func buildCloseSessionTool() -> [String: Any] {
        [
            "name": "close_session",
            "description": "Call this function when the conversation is finished, the user is satisfied, or the user says goodbye.",
            "parameters": [
                "type": "OBJECT",
                "properties": [:]
            ]
        ]
    }

    private func buildGenerateImageTool() -> [String: Any] {
        [
            "name": "generate_image",
            "description": "Call this function when the user asks you to generate, create, or draw an image. Provide a detailed prompt describing the image to generate.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "prompt": [
                        "type": "STRING",
                        "description": "A detailed description of the image to generate."
                    ]
                ],
                "required": ["prompt"]
            ]
        ]
    }

    private func sendJSON(_ object: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: object)
            if let jsonString = String(data: data, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                webSocket?.send(message) { [weak self] error in
                    if let error = error {
                        print("WebSocket send error: \(error)")
                        self?.callbacks?.onError(error)
                    }
                }
            }
        } catch {
            print("JSON serialization error: \(error)")
            callbacks?.onError(error)
        }
    }

    private func resolveLiveVoicePrompt() -> String {
        let prompt = UserDefaults.standard.string(forKey: Self.liveVoicePromptKey) ?? ""
        return prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.defaultLiveVoicePrompt : prompt
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue listening
                self.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.callbacks?.onError(error)
                self.disconnect()
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleJSONMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleJSONMessage(text)
            }
        @unknown default:
            break
        }
    }

    private func handleJSONMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        // Handle setup complete
        if let setupComplete = json["setupComplete"] as? [String: Any] {
            print("Gemini Live: Setup complete")
            isConnected = true
            callbacks?.onStatusChange(.listening)
            startAudioCapture()
            return
        }

        // Handle tool calls
        if let toolCall = json["toolCall"] as? [String: Any],
           let functionCalls = toolCall["functionCalls"] as? [[String: Any]] {
            handleToolCalls(functionCalls)
            return
        }

        // Handle audio output
        if let serverContent = json["serverContent"] as? [String: Any],
           let modelTurn = serverContent["modelTurn"] as? [String: Any],
           let parts = modelTurn["parts"] as? [[String: Any]] {

            for part in parts {
                if let inlineData = part["inlineData"] as? [String: Any],
                   let audioData = inlineData["data"] as? String {
                    handleAudioOutput(audioData)
                }
            }
        }
    }

    private func handleToolCalls(_ functionCalls: [[String: Any]]) {
        callbacks?.onStatusChange(.processing)

        for fc in functionCalls {
            guard let name = fc["name"] as? String,
                  let id = fc["id"] as? String
            else { continue }

            if name == "finalize_draft" {
                if let args = fc["args"] as? [String: Any] {
                    handleFinalizeDraft(args, callId: id)
                }
            } else if name == "close_session" {
                handleCloseSession(callId: id)
            } else if name == "generate_image" {
                if let args = fc["args"] as? [String: Any],
                   let prompt = args["prompt"] as? String {
                    handleGenerateImage(prompt, callId: id)
                }
            }
        }

        // Revert to listening after processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.isConnected else { return }
            self.callbacks?.onStatusChange(.listening)
        }
    }

    private func handleFinalizeDraft(_ args: [String: Any], callId: String) {
        // Parse the draft result
        if let intentDict = args["intent"] as? [String: Any],
           let form = args["form"] as? String {

            let intent = VoiceIntent(
                mode: intentDict["mode"] as? String ?? "live",
                action: intentDict["action"] as? String ?? "create",
                targetApp: intentDict["target_app"] as? String ?? "",
                language: intentDict["language"] as? String ?? "en",
                tone: intentDict["tone"] as? String ?? "neutral",
                instruction: intentDict["instruction"] as? String ?? "",
                inputText: intentDict["input_text"] as? String
            )

            let result = VoiceDraftResult(intent: intent, form: form)
            callbacks?.onDraftComplete(result)
        }

        // Send tool response
        sendToolResponse(callId: callId, name: "finalize_draft", response: ["result": "Draft displayed to user."])
    }

    private func handleCloseSession(callId: String) {
        sendToolResponse(callId: callId, name: "close_session", response: ["result": "Session closed."])
        callbacks?.onCloseIntent()
    }

    private func handleGenerateImage(_ prompt: String, callId: String) {
        callbacks?.onImageRequest(prompt)
        sendToolResponse(callId: callId, name: "generate_image", response: ["result": "Image generation started. The image will be displayed to the user."])
    }

    private func sendToolResponse(callId: String, name: String, response: [String: Any]) {
        let message: [String: Any] = [
            "toolResponse": [
                "functionResponses": [
                    [
                        "id": callId,
                        "name": name,
                        "response": response
                    ]
                ]
            ]
        ]
        sendJSON(message)
    }

    private func handleAudioOutput(_ base64Audio: String) {
        guard let audioData = Data(base64Encoded: base64Audio) else { return }

        callbacks?.onStatusChange(.speaking)
        audioPlayer?.playPCM16Data(audioData, sampleRate: 24000)
    }

    private func startAudioCapture() {
        audioRecorder = AudioRecorder()

        do {
            try audioRecorder?.startStreaming(
                onVisualizerUpdate: { [weak self] levels in
                    self?.callbacks?.onVisualizerUpdate(levels)
                },
                onAudioChunk: { [weak self] data in
                    self?.sendAudioChunk(data)
                }
            )
            print("✅ Audio capture started for Live mode")
        } catch {
            print("❌ Failed to start audio capture: \(error)")
            callbacks?.onError(error)
            // Disconnect since we can't capture audio
            disconnect()
        }
    }

    private func setupAudioPlayer() {
        audioPlayer = AudioPlayer()

        audioPlayer?.onPlaybackStarted = { [weak self] in
            self?.callbacks?.onStatusChange(.speaking)
        }

        audioPlayer?.onPlaybackFinished = { [weak self] in
            guard let self = self, self.isConnected else { return }
            self.callbacks?.onStatusChange(.listening)
        }

        do {
            try audioPlayer?.setup()
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension GeminiLiveService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed: \(closeCode)")
        isConnected = false
        callbacks?.onDisconnect()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // Ignore cancellation errors from our own disconnect
            if (error as NSError).code == NSURLErrorCancelled { return }
            print("WebSocket error: \(error)")
            callbacks?.onError(error)
        }
        disconnect()
    }
}
