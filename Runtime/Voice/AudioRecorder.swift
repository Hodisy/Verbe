import AVFoundation
import Foundation

// MARK: - Audio Recorder

final class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?

    private var onVisualizerUpdate: (([Float]) -> Void)?
    private var onAudioChunk: ((Data) -> Void)?

    private(set) var isRecording = false

    /// Cached permission status
    private(set) static var microphonePermissionGranted = false

    // Audio format for Gemini Live API (16kHz PCM16)
    private let liveInputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: true
    )!

    // MARK: - Permission Check

    /// Requests microphone permission using AVCaptureDevice (triggers macOS system popup)
    static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("✅ Microphone: already authorized")
            microphonePermissionGranted = true
            DispatchQueue.main.async { completion(true) }

        case .notDetermined:
            print("🔐 Microphone: requesting permission...")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                microphonePermissionGranted = granted
                print("🔐 Microphone permission response: \(granted ? "✅" : "❌")")
                DispatchQueue.main.async { completion(granted) }
            }

        case .denied, .restricted:
            print("❌ Microphone: denied or restricted")
            microphonePermissionGranted = false
            DispatchQueue.main.async { completion(false) }

        @unknown default:
            microphonePermissionGranted = false
            DispatchQueue.main.async { completion(false) }
        }
    }

    /// Checks current permission status without prompting
    static func checkMicrophonePermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        let granted = status == .authorized
        microphonePermissionGranted = granted
        return granted
    }

    // MARK: - Recording to File (Voice Command Mode)

    /// Start recording audio to a file for voice command mode
    func startRecordingToFile(onVisualizerUpdate: @escaping ([Float]) -> Void) throws -> URL {
        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        // Verify microphone permission before accessing audio hardware
        guard AudioRecorder.microphonePermissionGranted else {
            print("❌ [AudioRecorder] Microphone permission not granted")
            throw AudioRecorderError.permissionDenied
        }

        print("🎙️ [AudioRecorder] Starting file recording...")
        self.onVisualizerUpdate = onVisualizerUpdate

        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "voice_command_\(UUID().uuidString).m4a"
        let fileURL = tempDir.appendingPathComponent(filename)
        self.recordingURL = fileURL
        print("🎙️ [AudioRecorder] Recording to: \(fileURL.lastPathComponent)")

        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            print("❌ [AudioRecorder] Failed to create audio engine")
            throw AudioRecorderError.engineSetupFailed
        }

        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            print("❌ [AudioRecorder] Input node not available")
            throw AudioRecorderError.inputNodeNotAvailable
        }

        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("🎙️ [AudioRecorder] Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch, \(inputFormat.commonFormat.rawValue)")

        // Create audio file for recording
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioFile = try AVAudioFile(forWriting: fileURL, settings: settings)
        print("🎙️ [AudioRecorder] Audio file created with AAC format")

        // Install tap for recording and visualization
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        print("🎙️ [AudioRecorder] Tap installed with buffer size 1024")

        try audioEngine.start()
        print("🎙️ [AudioRecorder] Audio engine started")
        isRecording = true

        return fileURL
    }

    /// Stop recording and return the file URL
    func stopRecordingToFile() -> URL? {
        guard isRecording else {
            print("⚠️ [AudioRecorder] Not recording, cannot stop")
            return nil
        }

        print("🎙️ [AudioRecorder] Stopping recording...")
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioFile = nil
        isRecording = false

        if let url = recordingURL {
            print("🎙️ [AudioRecorder] Recording saved to: \(url.lastPathComponent)")
            // Log file size
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int {
                print("🎙️ [AudioRecorder] File size: \(fileSize) bytes")
            }
        }

        return recordingURL
    }

    // MARK: - Real-time Streaming (Live Mode)

    /// Start streaming audio for live mode
    func startStreaming(
        onVisualizerUpdate: @escaping ([Float]) -> Void,
        onAudioChunk: @escaping (Data) -> Void
    ) throws {
        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        // Verify microphone permission before accessing audio hardware
        guard AudioRecorder.microphonePermissionGranted else {
            print("❌ [AudioRecorder] Microphone permission not granted")
            throw AudioRecorderError.permissionDenied
        }

        self.onVisualizerUpdate = onVisualizerUpdate
        self.onAudioChunk = onAudioChunk

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw AudioRecorderError.engineSetupFailed
        }

        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            throw AudioRecorderError.inputNodeNotAvailable
        }

        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Install tap for streaming
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processStreamingBuffer(buffer)
        }

        try audioEngine.start()
        isRecording = true
    }

    /// Stop streaming
    func stopStreaming() {
        guard isRecording else { return }

        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()

        isRecording = false
        onAudioChunk = nil
    }

    // MARK: - Audio Processing

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Write to file
        if let audioFile = audioFile {
            try? audioFile.write(from: buffer)
        }

        // Update visualizer
        updateVisualizer(from: buffer)
    }

    private func processStreamingBuffer(_ buffer: AVAudioPCMBuffer) {
        // Update visualizer
        updateVisualizer(from: buffer)

        // Convert to PCM16 at 16kHz for Gemini Live API
        if let pcmData = convertToPCM16(buffer) {
            DispatchQueue.main.async { [weak self] in
                self?.onAudioChunk?(pcmData)
            }
        }
    }

    private func updateVisualizer(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS levels for visualization (8 bands)
        let bandCount = 8
        let samplesPerBand = frameLength / bandCount
        var levels: [Float] = []

        for band in 0..<bandCount {
            let start = band * samplesPerBand
            let end = min(start + samplesPerBand, frameLength)

            var sum: Float = 0
            for i in start..<end {
                let sample = channelData[i]
                sum += sample * sample
            }

            let rms = sqrt(sum / Float(end - start))
            // Scale to 0-1 range
            let level = min(1.0, rms * 5)
            levels.append(level)
        }

        DispatchQueue.main.async { [weak self] in
            self?.onVisualizerUpdate?(levels)
        }
    }

    private func convertToPCM16(_ buffer: AVAudioPCMBuffer) -> Data? {
        // Target format: 16kHz, mono, PCM Int16
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        ) else {
            print("❌ Failed to create target format")
            return nil
        }

        // Create converter from input format to target format
        guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
            print("❌ Failed to create audio converter")
            return nil
        }

        // Calculate output buffer capacity
        let inputSampleRate = buffer.format.sampleRate
        let outputSampleRate = targetFormat.sampleRate
        let ratio = outputSampleRate / inputSampleRate
        let outputCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        // Create output buffer
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputCapacity
        ) else {
            print("❌ Failed to create output buffer")
            return nil
        }

        // Perform conversion
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            print("❌ Conversion error: \(error)")
            return nil
        }

        // Convert buffer to Data
        guard let int16ChannelData = outputBuffer.int16ChannelData else {
            print("❌ No int16 channel data")
            return nil
        }

        let frameLength = Int(outputBuffer.frameLength)
        let data = Data(bytes: int16ChannelData[0], count: frameLength * MemoryLayout<Int16>.size)

        return data
    }
}

// MARK: - Audio Playback (for Live mode responses)

final class AudioPlayer {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioQueue: [AVAudioPCMBuffer] = []
    private var isPlaying = false

    // Audio format for Gemini Live API output (24kHz PCM16)
    private let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 24000,
        channels: 1,
        interleaved: false
    )!

    var onPlaybackStarted: (() -> Void)?
    var onPlaybackFinished: (() -> Void)?

    func setup() throws {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let audioEngine = audioEngine, let playerNode = playerNode else {
            throw AudioRecorderError.engineSetupFailed
        }

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)

        try audioEngine.start()
    }

    func playPCM16Data(_ data: Data, sampleRate: Double = 24000) {
        guard let playerNode = playerNode else { return }

        // Convert PCM16 to AVAudioPCMBuffer
        let frameCount = data.count / 2
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        data.withUnsafeBytes { rawBufferPointer in
            let int16Buffer = rawBufferPointer.bindMemory(to: Int16.self)
            if let floatChannelData = buffer.floatChannelData?[0] {
                for i in 0..<frameCount {
                    floatChannelData[i] = Float(int16Buffer[i]) / 32768.0
                }
            }
        }

        audioQueue.append(buffer)

        if !isPlaying {
            playNextBuffer()
        }
    }

    private func playNextBuffer() {
        guard !audioQueue.isEmpty, let playerNode = playerNode else {
            isPlaying = false
            DispatchQueue.main.async { [weak self] in
                self?.onPlaybackFinished?()
            }
            return
        }

        isPlaying = true
        DispatchQueue.main.async { [weak self] in
            self?.onPlaybackStarted?()
        }

        let buffer = audioQueue.removeFirst()

        playerNode.scheduleBuffer(buffer) { [weak self] in
            self?.playNextBuffer()
        }

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    func stop() {
        playerNode?.stop()
        audioQueue.removeAll()
        isPlaying = false
    }

    func cleanup() {
        stop()
        audioEngine?.stop()
        if let playerNode = playerNode {
            audioEngine?.detach(playerNode)
        }
        audioEngine = nil
        playerNode = nil
    }
}

// MARK: - Errors

enum AudioRecorderError: LocalizedError {
    case alreadyRecording
    case engineSetupFailed
    case inputNodeNotAvailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .alreadyRecording: return "Already recording"
        case .engineSetupFailed: return "Failed to setup audio engine"
        case .inputNodeNotAvailable: return "Microphone not available"
        case .permissionDenied: return "Microphone permission denied"
        }
    }
}

// MARK: - Audio Utilities

enum AudioUtils {
    /// Convert Data to base64 string
    static func dataToBase64(_ data: Data) -> String {
        data.base64EncodedString()
    }

    /// Convert base64 string to Data
    static func base64ToData(_ base64: String) -> Data? {
        Data(base64Encoded: base64)
    }

    /// Convert Float32 array to PCM16 Data
    static func float32ToPCM16(_ floatArray: [Float]) -> Data {
        var data = Data(count: floatArray.count * 2)
        data.withUnsafeMutableBytes { rawBufferPointer in
            let int16Buffer = rawBufferPointer.bindMemory(to: Int16.self)
            for (i, sample) in floatArray.enumerated() {
                let clampedSample = max(-1.0, min(1.0, sample))
                int16Buffer[i] = Int16(clampedSample * 32767)
            }
        }
        return data
    }

    /// Convert PCM16 Data to Float32 array
    static func pcm16ToFloat32(_ data: Data) -> [Float] {
        let frameCount = data.count / 2
        var floatArray: [Float] = Array(repeating: 0, count: frameCount)

        data.withUnsafeBytes { rawBufferPointer in
            let int16Buffer = rawBufferPointer.bindMemory(to: Int16.self)
            for i in 0..<frameCount {
                floatArray[i] = Float(int16Buffer[i]) / 32768.0
            }
        }

        return floatArray
    }
}
