import ApplicationServices
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow?
    var settingsWindow: NSWindow?
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var hotkeyModifiersDown = false
    private var lastTriggerTime: Date?

    private var fnKeyDown = false
    private var shiftKeyDown = false
    private var fnPressTime: Date?
    private var voiceModeTimer: Timer?
    private let voiceModeDelayMs: TimeInterval = 0.25 

    func applicationDidFinishLaunching(_: Notification) {
        print("🚀 App launched!")
        NSLog("🚀 App launched!")

        NSApp.setActivationPolicy(.accessory)
        print("📱 Activation policy set to .accessory")

        checkPermissions()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("⏰ Setting up hotkey after delay...")
            NSLog("⏰ Setting up hotkey after delay...")
            self.setupHotkey()
        }
    }

    func showOverlay() {
        print("📍 showOverlay called - AppDelegate id: \(ObjectIdentifier(self))")
        print("🪟 OverlayWindow id: \(overlayWindow.map(ObjectIdentifier.init) as Any)")
        let capturedText = captureSelectedText()
        print("📝 Captured text: \(capturedText ?? "nil")")

        if overlayWindow == nil {
            print("🪟 Creating new overlay window")
            overlayWindow = OverlayWindow()
        }

        overlayWindow?.state.capturedText = capturedText ?? ""
        overlayWindow?.show()
        print("✅ Overlay shown")
    }

    func checkPermissions() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let hasAX = AXIsProcessTrustedWithOptions(opts)
        print("🔐 Accessibility: \(hasAX ? "✅" : "❌")")

        let hasInput = CGPreflightListenEventAccess()
        print("🔐 Input Monitoring: \(hasInput ? "✅" : "❌")")

        if !hasInput {
            print("⚠️ Requesting Input Monitoring permission...")
            CGRequestListenEventAccess()
        }

        // Request microphone permission (triggers macOS system popup on first launch)
        AudioRecorder.requestMicrophonePermission { granted in
            print("🔐 Microphone: \(granted ? "✅" : "❌")")
            if !granted {
                print("⚠️ Microphone permission denied - voice features will not work")
            }
        }
    }

    func setupHotkey() {
        // Use NSEvent monitors to avoid CGEventTap interfering with system shortcuts
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierFlags(event.modifierFlags)
        }

        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierFlags(event.modifierFlags)
            return event
        }

        print("✅ Hotkey setup complete (NSEvent flagsChanged monitors)")
    }

    private func handleModifierFlags(_ flags: NSEvent.ModifierFlags) {
        let commandPressed = flags.contains(.command)
        let optionPressed = flags.contains(.option)
        let bothPressed = commandPressed && optionPressed
        hotkeyModifiersDown = bothPressed

        // Handle fn key for voice modes
        let fnPressed = flags.contains(.function)
        let shiftPressed = flags.contains(.shift)
        handleVoiceModeKeys(fnPressed: fnPressed, shiftPressed: shiftPressed)

        // Skip Cmd+Option overlay logic while voice mode is active
        let voiceMode = overlayWindow?.state.voiceState.mode ?? .none
        if voiceMode != .none { return }

        // Use overlay visibility as source of truth
        let isOverlayVisible = overlayWindow?.state.isVisible ?? false

        // print("⌨️ flagsChanged - Cmd:\(commandPressed) Opt:\(optionPressed) Fn:\(fnPressed) Shift:\(shiftPressed) | Overlay visible:\(isOverlayVisible)")

        // Show overlay when both keys are pressed AND overlay is not already visible
        if bothPressed, !isOverlayVisible {
            print("🔥 Showing overlay")
            DispatchQueue.main.async {
                self.showOverlay()
            }
            return
        }

        // Hide overlay when either key is released AND overlay IS visible AND auto-hide is enabled
        let shouldAutoHide = overlayWindow?.state.shouldAutoHideOnKeyRelease ?? true
        if !bothPressed, isOverlayVisible, shouldAutoHide {
            // Check if a bubble is hovered - if so, trigger it instead of hiding
            if let hoveredIndex = overlayWindow?.state.radialMenuState.hoveredIndex {
                // Debounce: prevent duplicate triggers within 100ms
                let now = Date()
                if let lastTrigger = lastTriggerTime, now.timeIntervalSince(lastTrigger) < 0.1 {
                    print("⏭️ Skipping duplicate trigger (debounced)")
                    return
                }
                lastTriggerTime = now

                if hoveredIndex == -1 {
                    // Center bubble (search) is hovered - expand search
                    print("🔍 Triggering search (key release on hover)")
                    DispatchQueue.main.async {
                        self.overlayWindow?.state.radialMenuState.isSearchExpanded = true
                        self.overlayWindow?.state.hasUserInteraction = true
                    }
                } else if hoveredIndex >= 0 {
                    // Recipe bubble is hovered - trigger recipe
                    let recipe = overlayWindow?.state.radialMenuState.recipeAt(slot: hoveredIndex)
                    print("🍳 Triggering recipe: \(recipe?.label ?? "unknown") (key release on hover)")
                    DispatchQueue.main.async {
                        if let recipe = recipe {
                            self.overlayWindow?.triggerRecipe(recipe)
                        }
                    }
                }
                return
            }

            print("🔓 Hiding overlay (auto-hide enabled)")
            DispatchQueue.main.async {
                self.overlayWindow?.hide()
            }
            return
        }
    }

    func captureSelectedText() -> String? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)

        var focusedElement: AnyObject?
        guard AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
            return fallbackCapture()
        }

        var selectedText: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText) == .success else {
            if hotkeyModifiersDown {
                // Avoid synthesizing Cmd+C while Cmd/Option are held.
                print("🛑 Skipping fallback capture: Cmd+Option still held")
                return nil
            }
            return fallbackCapture()
        }

        return selectedText as? String
    }

    func fallbackCapture() -> String? {
        let pasteboard = NSPasteboard.general
        let oldContent = pasteboard.string(forType: .string)

        pasteboard.clearContents()

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        Thread.sleep(forTimeInterval: 0.1)

        let captured = pasteboard.string(forType: .string)

        if let oldContent = oldContent {
            pasteboard.clearContents()
            pasteboard.setString(oldContent, forType: .string)
        }

        return captured
    }

    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSRunningApplication.current.activate(options: [.activateAllWindows])

        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.styleMask = [.titled, .closable, .miniaturizable]
            settingsWindow?.titleVisibility = .hidden
            settingsWindow?.titlebarAppearsTransparent = true
            settingsWindow?.setContentSize(NSSize(width: 500, height: 300))
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: settingsWindow,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    // MARK: - Voice Mode Handling

    private func handleVoiceModeKeys(fnPressed: Bool, shiftPressed: Bool) {
        let wasFnDown = fnKeyDown
        let wasShiftDown = shiftKeyDown

        fnKeyDown = fnPressed
        shiftKeyDown = shiftPressed

        // Only log on state changes to avoid spamming
        if fnPressed != wasFnDown || shiftPressed != wasShiftDown {
            print("🎹 Voice keys - fn:\(fnPressed)(was:\(wasFnDown)) shift:\(shiftPressed)(was:\(wasShiftDown))")
        }

        // fn key pressed (ignore if Cmd+Option overlay is active)
        if fnPressed && !wasFnDown {
            // Don't start voice mode if the overlay hotkey (Cmd+Option) is also active
            if hotkeyModifiersDown {
                print("⏭️ Ignoring fn press while Cmd+Option held")
                return
            }

            fnPressTime = Date()

            // Wait to see if shift is also pressed
            voiceModeTimer?.invalidate()
            voiceModeTimer = Timer.scheduledTimer(withTimeInterval: voiceModeDelayMs, repeats: false) { [weak self] _ in
                guard let self = self else { return }

                // After delay, check if fn is still held and shift is not pressed
                if self.fnKeyDown && !self.shiftKeyDown {
                    print("🎤 Starting Voice Command mode (fn held)")
                    DispatchQueue.main.async {
                        self.startVoiceCommandMode()
                    }
                }
            }
            return
        }

        // shift key pressed while fn is held → immediately start live mode
        if shiftPressed && !wasShiftDown && fnPressed {
            voiceModeTimer?.invalidate()
            voiceModeTimer = nil

            // If command mode is already running, stop it first
            let currentMode = overlayWindow?.state.voiceState.mode ?? .none
            if currentMode == .command {
                print("🔄 Cancelling Command mode before switching to Live")
                overlayWindow?.cancelVoiceCommand()
            }

            print("🔴 Starting Voice Live mode (fn+shift held)")
            DispatchQueue.main.async {
                self.startVoiceLiveMode()
            }
            return
        }

        // fn key released
        if !fnPressed && wasFnDown {
            voiceModeTimer?.invalidate()
            voiceModeTimer = nil

            // Check if we were in voice mode
            let voiceMode = overlayWindow?.state.voiceState.mode ?? .none

            if voiceMode == .command {
                print("🎤 Stopping Voice Command mode (fn released)")
                stopVoiceCommandMode()
            } else if voiceMode == .live {
                print("🔴 Stopping Voice Live mode (fn released)")
                stopVoiceLiveMode()
            }

            hideOverlayIfNoResult()
            return
        }

        // shift key released while in live mode → stop live mode
        if !shiftPressed && wasShiftDown {
            let voiceMode = overlayWindow?.state.voiceState.mode ?? .none
            if voiceMode == .live {
                print("🔴 Stopping Voice Live mode (shift released)")
                stopVoiceLiveMode()
                hideOverlayIfNoResult()
            }
            return
        }
    }

    private func startVoiceCommandMode() {
        ensureOverlayWindow()

        // Capture text before showing overlay
        let capturedText = captureSelectedText()
        overlayWindow?.state.capturedText = capturedText ?? ""

        // Start voice command recording
        overlayWindow?.startVoiceCommand()
    }

    private func stopVoiceCommandMode() {
        overlayWindow?.stopVoiceCommand()
    }

    private func startVoiceLiveMode() {
        ensureOverlayWindow()

        // Capture text before showing overlay
        let capturedText = captureSelectedText()
        overlayWindow?.state.capturedText = capturedText ?? ""

        // Start live conversation
        overlayWindow?.startVoiceLive()
    }

    private func stopVoiceLiveMode() {
        overlayWindow?.stopVoiceLive()
    }

    private func hideOverlayIfNoResult() {
        // After voice mode ends, hide overlay if no result is being shown
        // and no voice processing is still in progress.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self,
                  let overlay = self.overlayWindow,
                  overlay.state.isVisible,
                  !overlay.state.isShowingResponse,
                  !overlay.state.voiceState.isVoiceUIVisible else { return }
            print("🙈 Hiding overlay after voice mode (no result)")
            overlay.hide()
        }
    }

    private func ensureOverlayWindow() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
    }
}
