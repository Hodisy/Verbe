import Cocoa
import SwiftUI

// MARK: - Launcher State (Observable)

@Observable
final class LauncherState {
    var isVisible = false
    var capturedText: String = ""

    // LLM Response state
    var isShowingResponse = false {
        didSet {
            updateAutoHideState()
        }
    }

    // Auto-hide behavior: if true, menu hides when Cmd+Option keys are released
    var shouldAutoHideOnKeyRelease = true

    // Track if user has interacted (clicked bubble, expanded search, etc.)
    var hasUserInteraction = false {
        didSet {
            updateAutoHideState()
        }
    }

    // Delegates
    var radialMenuState: RadialMenuState
    var llmResponseState: LLMResponseState
    var voiceState: VoiceState

    private func updateAutoHideState() {
        // Disable auto-hide when:
        // 1. LLM response is showing
        // 2. User has interacted with the menu (search expanded, recipe clicked)
        shouldAutoHideOnKeyRelease = !isShowingResponse && !hasUserInteraction
    }

    init() {
        let settingsViewModel = SettingsViewModel()
        radialMenuState = RadialMenuState(recipes: settingsViewModel.customRecipes, maxBubbles: 3)
        llmResponseState = LLMResponseState()
        voiceState = VoiceState()
    }

    func refreshRecipes() {
        let settingsViewModel = SettingsViewModel()
        radialMenuState.recipes = settingsViewModel.customRecipes
    }
}

// MARK: - OverlayWindow

final class OverlayWindow: NSPanel {
    let state = LauncherState()
    private var scrollMonitor: Any?
    private var mouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var keyMonitor: Any?
    private var localKeyMonitor: Any?

    // Voice services
    private var voiceCommandService: VoiceCommandService?
    private var geminiLiveService: GeminiLiveService?

    init() {
        // Start with a placeholder rect - will be resized to full screen on show()
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .transient,
        ]

        let overlayView = OverlayView(state: state, window: self)
        contentView = NSHostingView(rootView: overlayView)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func show() {
        print("🎯 OverlayWindow.show() called")
        let mouseLocation = NSEvent.mouseLocation
        print("🖱️ Mouse location: \(mouseLocation)")

        // Cover the entire screen
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            print("❌ No screen found!")
            return
        }
        print("🖥️ Screen frame: \(screen.frame)")
        setFrame(screen.frame, display: true)

        // Store the menu center position (cursor location in screen coordinates)
        // Convert to view coordinates (origin at top-left, Y grows downward)
        let menuCenterInView = CGPoint(
            x: mouseLocation.x - screen.frame.minX,
            y: screen.frame.maxY - mouseLocation.y
        )
        state.radialMenuState.menuCenter = menuCenterInView
        print("📍 Menu center in view: \(menuCenterInView)")

        // Reload recipes from UserDefaults to pick up new/reordered recipes
        state.refreshRecipes()

        state.isVisible = true
        state.isShowingResponse = false
        state.hasUserInteraction = false
        state.radialMenuState.reset()
        state.radialMenuState.currentIndex = 0
        state.radialMenuState.isSearchExpanded = false
        state.radialMenuState.searchText = ""
        state.llmResponseState.responseText = ""
        state.llmResponseState.isStreaming = false

        print("🔄 State updated - isVisible: \(state.isVisible), shouldAutoHide: \(state.shouldAutoHideOnKeyRelease)")
        makeKeyAndOrderFront(nil)
        print("🪟 makeKeyAndOrderFront called")
        setupMonitors()
        print("👂 Monitors setup complete")
    }

    func hide() {
        print("🙈 OverlayWindow.hide() called")
        print("🔄 Before hide - isVisible: \(state.isVisible)")

        // Clean up voice services
        voiceCommandService?.cancel()
        voiceCommandService = nil
        geminiLiveService?.disconnect()
        geminiLiveService = nil
        state.voiceState.reset()

        state.isVisible = false
        state.radialMenuState.isSearchExpanded = false
        state.radialMenuState.searchText = ""
        removeMonitors()
        orderOut(nil)
        print("✅ Hide complete - isVisible: \(state.isVisible)")
    }

    private func setupMonitors() {
        // Scroll monitor
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScroll(event)
            return nil // Consume event
        }

        // Global mouse monitor - tracks mouse even outside our window
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleGlobalMouseMove(event)
        }

        // Key monitor for Escape (global since the panel is non-activating)
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.state.isVisible else { return }
            if event.keyCode == 53 { // Escape
                DispatchQueue.main.async {
                    self.hide()
                }
            }
        }

        // Local key monitor for Space (to expand search bar)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.state.isVisible else { return event }

            // Space key (49) expands search when radial menu is showing and search is not expanded
            if event.keyCode == 49,
               !self.state.isShowingResponse,
               !self.state.voiceState.isVoiceUIVisible,
               !self.state.radialMenuState.isSearchExpanded {
                DispatchQueue.main.async {
                    self.state.radialMenuState.isSearchExpanded = true
                    self.state.hasUserInteraction = true
                }
                return nil // Consume event
            }

            return event
        }
    }

    private func handleGlobalMouseMove(_: NSEvent) {
        guard state.isVisible, !state.isShowingResponse else { return }

        // Convert screen coordinates to view coordinates
        let screenLocation = NSEvent.mouseLocation
        let windowFrame = frame

        // View coordinates: origin at top-left, Y grows downward
        let viewX = screenLocation.x - windowFrame.minX
        let viewY = windowFrame.maxY - screenLocation.y

        // Calculate position relative to menu center
        let menuCenter = state.radialMenuState.menuCenter
        let dx = viewX - menuCenter.x
        let dy = viewY - menuCenter.y

        // Update hover state - pass the mouse position relative to menu center
        // The RadialMenuView expects coordinates relative to its own frame (200x200)
        let menuSize: CGFloat = 200
        let localPoint = CGPoint(
            x: dx + menuSize / 2,
            y: dy + menuSize / 2
        )
        state.radialMenuState.updateHover(at: localPoint, in: CGSize(width: menuSize, height: menuSize))
    }

    private func removeMonitors() {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }

    private func handleScroll(_ event: NSEvent) {
        guard state.isVisible, !state.isShowingResponse else { return }
        state.radialMenuState.scroll(delta: event.scrollingDeltaY)
    }

    func triggerCustomPrompt(_ text: String) {
        let recipe = Recipe(
            icon: "text.bubble",
            label: "Custom Prompt",
            systemPrompt: text,
            color: .purple,
            glow: .purple
        )
        triggerRecipe(recipe)
    }

    func triggerRecipe(_ recipe: Recipe) {
        state.llmResponseState.reset()
        state.llmResponseState.triggeredRecipe = recipe
        state.isShowingResponse = true

        // Handle different recipe types
        if recipe.isVisionRecipe {
            triggerVisionRecipe(recipe)
        } else if recipe.isImageGenRecipe {
            triggerImageGenRecipe(recipe)
        } else {
            triggerTextRecipe(recipe)
        }
    }

    private func triggerTextRecipe(_ recipe: Recipe) {
        state.llmResponseState.isStreaming = true

        let systemPrompt = recipe.systemPrompt
        let userMessage = state.capturedText.isEmpty ? "unknown" : state.capturedText

        GeminiService.shared.streamCompletionAsync(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            onChunk: { [weak self] chunk in
                self?.state.llmResponseState.responseText += chunk
            },
            onComplete: { [weak self] in
                self?.state.llmResponseState.isStreaming = false
            },
            onError: { [weak self] error in
                self?.state.llmResponseState.responseText = "Error: \(error.localizedDescription)"
                self?.state.llmResponseState.isStreaming = false
            }
        )
    }

    private func triggerVisionRecipe(_ recipe: Recipe) {
        // Launch the async capture on the main actor, updating UI state safely.
        Task { @MainActor in
            state.llmResponseState.isStreaming = true
            state.llmResponseState.responseText = "Capturing screen..."

            do {
                // Capture the frontmost window (or full screen)
                let screenshot = try await ScreenCaptureService.shared.captureFrontmostWindow()
                guard let imageBase64 = ScreenCaptureService.shared.imageToBase64(screenshot) else {
                    state.llmResponseState.responseText = "Error: Failed to encode screenshot"
                    state.llmResponseState.isStreaming = false
                    return
                }

                state.llmResponseState.responseText = ""

                let prompt = state.capturedText.isEmpty
                    ? "Analyze this screenshot."
                    : "User context: \(state.capturedText)\n\nAnalyze this screenshot."

                GeminiService.shared.analyzeImageStreaming(
                    imageBase64: imageBase64,
                    prompt: prompt,
                    systemPrompt: recipe.systemPrompt,
                    onChunk: { [weak self] chunk in
                        self?.state.llmResponseState.responseText += chunk
                    },
                    onComplete: { [weak self] in
                        self?.state.llmResponseState.isStreaming = false
                    },
                    onError: { [weak self] error in
                        self?.state.llmResponseState.responseText = "Error: \(error.localizedDescription)"
                        self?.state.llmResponseState.isStreaming = false
                    }
                )
            } catch {
                state.llmResponseState.responseText = "Error: \(error.localizedDescription)"
                state.llmResponseState.isStreaming = false
            }
        }
    }

    private func triggerImageGenRecipe(_ recipe: Recipe) {
        state.llmResponseState.isGeneratingImage = true
        state.llmResponseState.imageGenerationProgress = "Generating image..."

        let prompt = state.capturedText.isEmpty
            ? "A beautiful artistic image"
            : state.capturedText

        GeminiService.shared.generateImage(prompt: prompt) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let imageData):
                if let nsImage = NSImage(data: imageData) {
                    self.state.llmResponseState.generatedImage = nsImage
                } else {
                    self.state.llmResponseState.responseText = "Error: Failed to decode image"
                }
            case .failure(let error):
                self.state.llmResponseState.responseText = "Error: \(error.localizedDescription)"
            }
            self.state.llmResponseState.isGeneratingImage = false
        }
    }

    private func buildSystemPrompt(for recipe: Recipe) -> String {
        recipe.systemPrompt
    }

    func insertResponse() {
        let text = state.llmResponseState.responseText
        hide()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.insertText(text)
        }
    }

    func copyToClipboard() {
        NSPasteboard.general.clearContents()

        // Copy image if available, otherwise copy text
        if let image = state.llmResponseState.generatedImage {
            NSPasteboard.general.writeObjects([image])
        } else {
            NSPasteboard.general.setString(state.llmResponseState.responseText, forType: .string)
        }
    }

    func insertText(_ text: String) {
        let pasteboard = NSPasteboard.general
        let oldContent = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        Thread.sleep(forTimeInterval: 0.05)

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let oldContent = oldContent {
                pasteboard.clearContents()
                pasteboard.setString(oldContent, forType: .string)
            }
        }
    }

    // MARK: - Voice Command Mode

    func startVoiceCommand() {
        print("🎤 OverlayWindow.startVoiceCommand()")

        // Check microphone permission before attempting to record
        guard AudioRecorder.checkMicrophonePermission() else {
            print("❌ Microphone permission not granted")
            showForVoiceMode()
            state.voiceState.startRecording(mode: .command)
            state.voiceState.setError(
                "Microphone access required. Open System Settings → Privacy & Security → Microphone to enable.",
                needsPermissionSettings: true
            )
            return
        }

        // Show UI and set state
        showForVoiceMode()
        state.voiceState.startRecording(mode: .command)
        print("🎤 Voice state set: mode=\(state.voiceState.mode), processing=\(state.voiceState.processingState)")

        // Create and start voice command service
        voiceCommandService = VoiceCommandService()

        let context = VoiceCommandService.UserContext(
            userName: "User",
            targetApp: getTargetAppName(),
            selectedText: state.capturedText
        )

        do {
            try voiceCommandService?.startRecording(
                context: context,
                onVisualizerUpdate: { [weak self] levels in
                    self?.state.voiceState.updateVisualizerData(levels)
                },
                onDurationUpdate: { [weak self] duration in
                    self?.state.voiceState.recordingDuration = duration
                }
            )
            print("✅ Voice recording started successfully")
        } catch {
            print("❌ Failed to start voice recording: \(error)")
            state.voiceState.setError(error.localizedDescription)
        }
    }

    /// Cancel voice command without processing (used when switching to live mode)
    func cancelVoiceCommand() {
        print("🎤 OverlayWindow.cancelVoiceCommand()")
        voiceCommandService?.cancel()
        voiceCommandService = nil
        state.voiceState.reset()
    }

    func stopVoiceCommand() {
        print("🎤 OverlayWindow.stopVoiceCommand()")

        state.voiceState.stopRecording()

        voiceCommandService?.stopRecordingAndProcess { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let draftResult):
                print("✅ Voice command result: \(draftResult.form)")
                self.state.voiceState.setResult(draftResult)

                // Show the result in the LLM response view
                self.state.llmResponseState.responseText = draftResult.form
                self.state.llmResponseState.isStreaming = false
                self.state.llmResponseState.triggeredRecipe = Recipe(
                    icon: "mic.fill",
                    label: "Voice Command",
                    systemPrompt: draftResult.intent.instruction,
                    color: .red,
                    glow: .red
                )
                self.state.isShowingResponse = true

            case .failure(let error):
                print("❌ Voice command error: \(error)")
                self.state.voiceState.setError(error.localizedDescription)
            }

            self.voiceCommandService = nil
        }
    }

    // MARK: - Voice Live Mode

    func startVoiceLive() {
        print("🔴 OverlayWindow.startVoiceLive()")

        // Check microphone permission before attempting to record
        guard AudioRecorder.checkMicrophonePermission() else {
            print("❌ Microphone permission not granted")
            showForVoiceMode()
            state.voiceState.startRecording(mode: .live)
            state.voiceState.setError(
                "Microphone access required. Open System Settings → Privacy & Security → Microphone to enable.",
                needsPermissionSettings: true
            )
            return
        }

        // Show UI and set state
        showForVoiceMode()
        state.voiceState.startRecording(mode: .live)
        print("🔴 Voice state set: mode=\(state.voiceState.mode), liveStatus=\(state.voiceState.liveStatus)")

        // Create and connect Gemini Live service
        geminiLiveService = GeminiLiveService()

        let context = GeminiLiveService.UserContext(
            userName: "User",
            targetApp: getTargetAppName(),
            selectedText: state.capturedText
        )

        let callbacks = GeminiLiveService.LiveServiceCallbacks(
            onVisualizerUpdate: { [weak self] levels in
                self?.state.voiceState.updateVisualizerData(levels)
            },
            onDraftComplete: { [weak self] result in
                guard let self = self else { return }
                print("✅ Live draft complete: \(result.form)")
                self.state.voiceState.setResult(result)

                // Clear any previous image before showing text draft
                self.state.llmResponseState.generatedImage = nil
                self.state.llmResponseState.isGeneratingImage = false

                // Show the result in the LLM response view
                self.state.llmResponseState.responseText = result.form
                self.state.llmResponseState.isStreaming = false
                self.state.llmResponseState.triggeredRecipe = Recipe(
                    icon: "waveform",
                    label: "Live Conversation",
                    systemPrompt: result.intent.instruction,
                    color: .red,
                    glow: .red
                )
                self.state.isShowingResponse = true
            },
            onImageRequest: { [weak self] prompt in
                guard let self = self else { return }
                print("🖼️ Live image request: \(prompt.prefix(100))...")

                self.state.llmResponseState.reset()
                self.state.llmResponseState.isGeneratingImage = true
                self.state.llmResponseState.imageGenerationProgress = "Generating image..."
                self.state.llmResponseState.triggeredRecipe = Recipe(
                    icon: "photo",
                    label: "Image Generation",
                    systemPrompt: prompt,
                    color: .purple,
                    glow: .purple
                )
                self.state.isShowingResponse = true

                GeminiService.shared.generateImage(prompt: prompt) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let imageData):
                        if let nsImage = NSImage(data: imageData) {
                            self.state.llmResponseState.generatedImage = nsImage
                        } else {
                            self.state.llmResponseState.responseText = "Error: Failed to decode image"
                        }
                    case .failure(let error):
                        self.state.llmResponseState.responseText = "Error: \(error.localizedDescription)"
                    }
                    self.state.llmResponseState.isGeneratingImage = false
                }
            },
            onStatusChange: { [weak self] status in
                self?.state.voiceState.updateLiveStatus(status)
            },
            onDisconnect: { [weak self] in
                self?.state.voiceState.reset()
            },
            onCloseIntent: { [weak self] in
                self?.stopVoiceLive()
            },
            onError: { [weak self] error in
                print("❌ Live service error: \(error)")
                self?.state.voiceState.setError(error.localizedDescription)
            }
        )

        geminiLiveService?.connect(context: context, callbacks: callbacks)
        print("✅ Voice Live service connected")
    }

    func stopVoiceLive() {
        print("🔴 OverlayWindow.stopVoiceLive()")

        // Reset voice state immediately so the UI clears before async cleanup
        if state.voiceState.processingState != .completed {
            state.voiceState.reset()
        }

        geminiLiveService?.disconnect()
        geminiLiveService = nil
    }

    // MARK: - Voice Mode Helpers

    private func showForVoiceMode() {
        print("🎯 OverlayWindow.showForVoiceMode()")

        let mouseLocation = NSEvent.mouseLocation

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            print("❌ No screen found!")
            return
        }

        setFrame(screen.frame, display: true)

        // Store the menu center position
        let menuCenterInView = CGPoint(
            x: mouseLocation.x - screen.frame.minX,
            y: screen.frame.maxY - mouseLocation.y
        )
        state.radialMenuState.menuCenter = menuCenterInView

        state.isVisible = true
        state.isShowingResponse = false
        state.hasUserInteraction = true // Prevent auto-hide during voice mode
        state.shouldAutoHideOnKeyRelease = false

        makeKeyAndOrderFront(nil)
        setupMonitors()
    }

    private func getTargetAppName() -> String {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            return frontApp.localizedName ?? "Unknown"
        }
        return "Unknown"
    }

    // MARK: - Insert Voice Result

    func insertVoiceResult() {
        guard let result = state.voiceState.draftResult else { return }

        let text = result.form
        hide()
        state.voiceState.reset()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.insertText(text)
        }
    }

    func copyVoiceResult() {
        guard let result = state.voiceState.draftResult else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.form, forType: .string)
    }
}
