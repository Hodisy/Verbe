import Foundation

// MARK: - Gemini Service (Streaming Text API)

final class GeminiService {
    static let shared = GeminiService()

    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let model = "gemini-3-flash-preview"

    private init() {
        // Load API key from environment or UserDefaults
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            self.apiKey = envKey
        } else if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !storedKey.isEmpty {
            self.apiKey = storedKey
        } else {
            // Fallback - you should set this via Settings
            self.apiKey = ""
        }
    }

    // MARK: - Public API

    func streamCompletionAsync(
        systemPrompt: String,
        userMessage: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        print("🚀 GeminiService.streamCompletionAsync called")
        print("📝 User message: \(userMessage.prefix(100))...")
        print("🧠 System prompt: \(systemPrompt.prefix(100))...")

        guard !apiKey.isEmpty else {
            print("❌ API key is missing")
            onError(GeminiError.missingApiKey)
            return
        }

        let urlString = "\(baseURL)/\(model):streamGenerateContent?alt=sse&key=\(apiKey)"
        print("🔗 URL: \(urlString.replacingOccurrences(of: apiKey, with: "***"))")

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            onError(GeminiError.invalidURL)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": userMessage]]
                ]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": 1.0,
                "maxOutputTokens": 2048,
                "thinkingConfig": [
                    "thinkingLevel": "minimal"
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 Request body: \(bodyString.prefix(500))...")
            }
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            onError(error)
            return
        }

        print("🔄 Starting URLSession data task...")
        let delegate = GeminiStreamDelegate(onChunk: onChunk, onComplete: onComplete, onError: onError)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
        print("✅ Data task started")
    }

    /// Non-streaming completion for structured output (JSON mode)
    func generateStructuredOutput<T: Decodable>(
        systemPrompt: String,
        userMessage: String,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard !apiKey.isEmpty else {
            completion(.failure(GeminiError.missingApiKey))
            return
        }

        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(GeminiError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": userMessage]]
                ]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": 1.0,
                "responseMimeType": "application/json",
                "thinkingConfig": [
                    "thinkingLevel": "minimal"
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(GeminiError.noData)) }
                return
            }

            do {
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                if let text = geminiResponse.candidates?.first?.content?.parts?.first?.text {
                    let result = try JSONDecoder().decode(T.self, from: Data(text.utf8))
                    DispatchQueue.main.async { completion(.success(result)) }
                } else {
                    DispatchQueue.main.async { completion(.failure(GeminiError.invalidResponse)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    /// Process audio with Gemini (for voice command mode)
    func processAudioCommand(
        audioData: Data,
        mimeType: String,
        systemPrompt: String,
        completion: @escaping (Result<VoiceDraftResult, Error>) -> Void
    ) {
        print("🤖 [GeminiService] processAudioCommand called")
        print("🤖 [GeminiService] Audio data: \(audioData.count) bytes, mimeType: \(mimeType)")
        print("🤖 [GeminiService] System prompt: \(systemPrompt.prefix(100))...")

        guard !apiKey.isEmpty else {
            print("❌ [GeminiService] API key is missing")
            completion(.failure(GeminiError.missingApiKey))
            return
        }

        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        print("🤖 [GeminiService] URL: \(urlString.replacingOccurrences(of: apiKey, with: "***"))")

        guard let url = URL(string: urlString) else {
            print("❌ [GeminiService] Invalid URL")
            completion(.failure(GeminiError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Audio = audioData.base64EncodedString()
        print("🤖 [GeminiService] Base64 audio: \(base64Audio.count) chars")

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "inlineData": [
                                "mimeType": mimeType,
                                "data": base64Audio
                            ]
                        ],
                        ["text": "Process this audio command."]
                    ]
                ]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": 1.0,
                "responseMimeType": "application/json",
                "responseSchema": VoiceDraftResult.jsonSchema,
                "thinkingConfig": [
                    "thinkingLevel": "minimal"
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("🤖 [GeminiService] Request body created: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("❌ [GeminiService] Failed to serialize JSON: \(error)")
            completion(.failure(error))
            return
        }

        print("🤖 [GeminiService] Sending request to Gemini...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [GeminiService] Network error: \(error)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("🤖 [GeminiService] HTTP Status: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("❌ [GeminiService] No data received")
                DispatchQueue.main.async { completion(.failure(GeminiError.noData)) }
                return
            }

            print("🤖 [GeminiService] Received \(data.count) bytes")

            // Log raw response for debugging
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("🤖 [GeminiService] Raw response: \(rawResponse.prefix(500))...")
            }

            do {
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                print("🤖 [GeminiService] Decoded GeminiResponse")

                if let text = geminiResponse.candidates?.first?.content?.parts?.first?.text {
                    print("🤖 [GeminiService] Extracted text: \(text.prefix(200))...")
                    let result = try JSONDecoder().decode(VoiceDraftResult.self, from: Data(text.utf8))
                    print("✅ [GeminiService] Successfully decoded VoiceDraftResult")
                    print("✅ [GeminiService] Intent: \(result.intent.action)")
                    print("✅ [GeminiService] Form length: \(result.form.count) chars")
                    DispatchQueue.main.async { completion(.success(result)) }
                } else {
                    print("❌ [GeminiService] Invalid response - no text in candidates")
                    DispatchQueue.main.async { completion(.failure(GeminiError.invalidResponse)) }
                }
            } catch {
                print("❌ [GeminiService] Decoding error: \(error)")
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Vision API (Image Analysis)

    /// Analyze an image with Gemini Vision
    func analyzeImageStreaming(
        imageBase64: String,
        prompt: String,
        systemPrompt: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        print("🚀 GeminiService.analyzeImageStreaming called")
        print("📝 Prompt: \(prompt.prefix(100))...")
        print("🖼️ Image size: \(imageBase64.count) chars")

        guard !apiKey.isEmpty else {
            print("❌ API key is missing")
            onError(GeminiError.missingApiKey)
            return
        }

        let urlString = "\(baseURL)/\(model):streamGenerateContent?alt=sse&key=\(apiKey)"
        print("🔗 URL: \(urlString.replacingOccurrences(of: apiKey, with: "***"))")

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            onError(GeminiError.invalidURL)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": imageBase64
                            ]
                        ],
                        ["text": prompt]
                    ]
                ]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": 1.0,
                "maxOutputTokens": 4096,
                "thinkingConfig": [
                    "thinkingLevel": "high"
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📤 Vision request body created (image + prompt)")
        } catch {
            print("❌ Failed to serialize vision request body: \(error)")
            onError(error)
            return
        }

        print("🔄 Starting vision URLSession data task...")
        let delegate = GeminiStreamDelegate(onChunk: onChunk, onComplete: onComplete, onError: onError)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
        print("✅ Vision data task started")
    }

    // MARK: - Image Generation (Gemini 3 Pro Image)

    /// Dedicated session for image generation (avoids HTTP/2 coalescing issues with URLSession.shared)
    private lazy var imageSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    /// Generate an image using Gemini 3 Pro Image
    func generateImage(
        prompt: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        generateImageRequest(prompt: prompt, attempt: 1, completion: completion)
    }

    private func generateImageRequest(
        prompt: String,
        attempt: Int,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard !apiKey.isEmpty else {
            completion(.failure(GeminiError.missingApiKey))
            return
        }

        let imageGenModel = "gemini-3-pro-image-preview"
        let urlString = "\(baseURL)/\(imageGenModel):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(GeminiError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": prompt]]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["TEXT", "IMAGE"]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        print("🖼️ Image generation attempt \(attempt)...")

        imageSession.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                let nsError = error as NSError
                // Retry once on connection lost (-1005) or connection reset (-1004)
                if attempt < 2 && (nsError.code == -1005 || nsError.code == -1004) {
                    print("⚠️ Connection error (\(nsError.code)), retrying...")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        self?.generateImageRequest(prompt: prompt, attempt: attempt + 1, completion: completion)
                    }
                    return
                }
                print("❌ Image generation network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(GeminiError.noData)) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("❌ Image generation error (\(httpResponse.statusCode)): \(rawResponse.prefix(500))")
                }
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]] {

                    for part in parts {
                        if let inlineData = part["inlineData"] as? [String: Any],
                           let base64Data = inlineData["data"] as? String,
                           let imageData = Data(base64Encoded: base64Data) {
                            DispatchQueue.main.async { completion(.success(imageData)) }
                            return
                        }
                    }
                    DispatchQueue.main.async { completion(.failure(GeminiError.noImageInResponse)) }
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("❌ Image generation API error: \(message)")
                    }
                    DispatchQueue.main.async { completion(.failure(GeminiError.invalidResponse)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}

// MARK: - Stream Delegate

private class GeminiStreamDelegate: NSObject, URLSessionDataDelegate {
    private let onChunk: (String) -> Void
    private let onComplete: () -> Void
    private let onError: (Error) -> Void
    private var buffer = ""

    init(
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onChunk = onChunk
        self.onComplete = onComplete
        self.onError = onError
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else {
            print("⚠️ GeminiStream: Failed to decode data as UTF-8")
            return
        }

        print("📦 GeminiStream: Received chunk (\(data.count) bytes)")
        buffer += text

        // SSE format uses double newlines to separate events
        while let eventRange = buffer.range(of: "\n\n") {
            let event = String(buffer[..<eventRange.lowerBound])
            buffer = String(buffer[eventRange.upperBound...])
            processEvent(event)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ GeminiStream: Completed with error: \(error.localizedDescription)")
            DispatchQueue.main.async { self.onError(error) }
        } else {
            print("✅ GeminiStream: Completed successfully")
            // Process any remaining events in buffer
            if !buffer.isEmpty {
                print("📝 GeminiStream: Processing remaining buffer (\(buffer.count) chars)")
                processEvent(buffer.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            DispatchQueue.main.async { self.onComplete() }
        }
    }

    private func processEvent(_ event: String) {
        let trimmed = event.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip empty events
        guard !trimmed.isEmpty else { return }

        // SSE events can have multiple lines; we only care about lines starting with "data: "
        let lines = trimmed.components(separatedBy: "\n")
        for line in lines {
            let lineContent = line.trimmingCharacters(in: .whitespaces)

            guard lineContent.hasPrefix("data: ") else {
                continue
            }

            let jsonString = String(lineContent.dropFirst(6))

            guard let jsonData = jsonString.data(using: .utf8) else {
                print("⚠️ GeminiStream: Failed to encode JSON string")
                continue
            }

            guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                print("⚠️ GeminiStream: Failed to parse JSON from event")
                continue
            }

            // Check for errors in response
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ GeminiStream: API error: \(message)")
                DispatchQueue.main.async {
                    self.onError(GeminiError.connectionFailed)
                }
                return
            }

            // Extract text from Gemini SSE response
            if let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String,
               !text.isEmpty {
                print("✨ GeminiStream: Received text chunk (\(text.count) chars): \(text.prefix(50))...")
                DispatchQueue.main.async { self.onChunk(text) }
            }
        }
    }
}

// MARK: - Response Models

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?

    struct Candidate: Decodable {
        let content: Content?
    }

    struct Content: Decodable {
        let parts: [Part]?
    }

    struct Part: Decodable {
        let text: String?
    }
}

// MARK: - Voice Draft Result

public struct VoiceDraftResult: Codable {
    public let intent: VoiceIntent
    public let form: String

    public static var jsonSchema: [String: Any] {
        [
            "type": "object",
            "properties": [
                "intent": [
                    "type": "object",
                    "properties": [
                        "mode": ["type": "string", "enum": ["command", "live"]],
                        "action": ["type": "string", "enum": ["edit", "create"]],
                        "target_app": ["type": "string"],
                        "language": ["type": "string"],
                        "tone": ["type": "string"],
                        "instruction": ["type": "string"],
                        "input_text": ["type": "string"]
                    ],
                    "required": ["mode", "action", "target_app", "language", "tone", "instruction"]
                ],
                "form": [
                    "type": "string",
                    "description": "The final formatted text output ready to be sent/pasted."
                ]
            ],
            "required": ["intent", "form"]
        ]
    }

    public init(intent: VoiceIntent, form: String) {
        self.intent = intent
        self.form = form
    }
}

public struct VoiceIntent: Codable {
    public let mode: String
    public let action: String
    public let targetApp: String
    public let language: String
    public let tone: String
    public let instruction: String
    public let inputText: String?

    public init(mode: String, action: String, targetApp: String, language: String, tone: String, instruction: String, inputText: String?) {
        self.mode = mode
        self.action = action
        self.targetApp = targetApp
        self.language = language
        self.tone = tone
        self.instruction = instruction
        self.inputText = inputText
    }

    enum CodingKeys: String, CodingKey {
        case mode, action, language, tone, instruction
        case targetApp = "target_app"
        case inputText = "input_text"
    }
}

// MARK: - Errors

public enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case missingApiKey
    case connectionFailed
    case audioEncodingError
    case imageGenerationFailed
    case noImageInResponse

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid response from Gemini"
        case .noData: return "No data received"
        case .missingApiKey: return "Gemini API key not configured. Set it in Settings."
        case .connectionFailed: return "Failed to connect to Gemini"
        case .audioEncodingError: return "Failed to encode audio data"
        case .imageGenerationFailed: return "Failed to generate image"
        case .noImageInResponse: return "No image in response"
        }
    }
}
