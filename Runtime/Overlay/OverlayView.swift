import SwiftUI

// MARK: - Voice Status Badge

struct VoiceStatusBadge: View {
    let voiceState: VoiceState

    private var modeLabel: String {
        switch voiceState.mode {
        case .command: return "Voice Command"
        case .live: return "Voice Live"
        case .none: return voiceState.errorMessage != nil ? "Voice Error" : ""
        }
    }

    private var modeIcon: String {
        switch voiceState.mode {
        case .command: return "mic.fill"
        case .live: return "waveform"
        case .none: return voiceState.errorMessage != nil ? "exclamationmark.triangle.fill" : "mic"
        }
    }

    private var statusLabel: String {
        if let error = voiceState.errorMessage {
            return error
        }

        switch voiceState.mode {
        case .command:
            switch voiceState.processingState {
            case .idle: return "Ready"
            case .recording: return "Listening..."
            case .processing: return "Processing..."
            case .completed: return "Done"
            }
        case .live:
            switch voiceState.liveStatus {
            case .off: return "Starting..."
            case .connecting: return "Connecting..."
            case .listening: return "Listening..."
            case .speaking: return "Speaking..."
            case .processing: return "Thinking..."
            case .completed: return "Done"
            }
        case .none:
            return voiceState.errorMessage ?? ""
        }
    }

    private var statusColor: Color {
        if voiceState.errorMessage != nil {
            return .red
        }

        switch voiceState.mode {
        case .command:
            switch voiceState.processingState {
            case .recording: return .green
            case .processing: return .orange
            default: return .secondary
            }
        case .live:
            switch voiceState.liveStatus {
            case .listening: return .green
            case .speaking: return .blue
            case .processing: return .orange
            case .connecting: return .yellow
            default: return .secondary
            }
        case .none:
            return voiceState.errorMessage != nil ? .red : .secondary
        }
    }

    private var isActive: Bool {
        voiceState.processingState == .recording ||
        voiceState.liveStatus == .listening ||
        voiceState.liveStatus == .speaking
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: modeIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(modeLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(nsColor: .controlTextColor))

                Text(statusLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect()
    }
}

// MARK: - Overlay View

struct OverlayView: View {
    let state: LauncherState
    weak var window: OverlayWindow?

    private let menuSize: CGFloat = 200
    private let expandedMenuSize: CGFloat = 450

    private var hoveredRecipe: Recipe? {
        guard let index = state.radialMenuState.hoveredIndex, index >= 0 else { return nil }
        return state.radialMenuState.recipeAt(slot: index)
    }

    private var shouldShowVoiceBadge: Bool {
        state.voiceState.mode != .none || state.voiceState.errorMessage != nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        window?.hide()
                    }

                if state.isVisible {
                    // Voice recording mode
                    if state.voiceState.isVoiceUIVisible && !state.isShowingResponse {
                        VoiceRecordingView(
                            state: state.voiceState,
                            onClose: {
                                window?.hide()
                            }
                        )
                        .position(
                            x: state.radialMenuState.menuCenter.x,
                            y: state.radialMenuState.menuCenter.y
                        )
                        .transition(.scale(scale: 0.8, anchor: .center).combined(with: .opacity))
                    } else if state.isShowingResponse {
                        LLMResponseView(
                            state: state.llmResponseState,
                            onInsert: {
                                print("LLMResponseView onInsert tapped, window: \(window.map(ObjectIdentifier.init) as Any)")
                                window?.insertResponse()
                            },
                            onCopy: {
                                print("LLMResponseView onCopy tapped, window: \(window.map(ObjectIdentifier.init) as Any)")
                                window?.copyToClipboard()
                            },
                            onClose: {
                                print("LLMResponseView onClose tapped, window: \(window.map(ObjectIdentifier.init) as Any)")
                                window?.hide()
                            }
                        )
                        .frame(width: 400, height: 400)
                        .position(
                            x: state.radialMenuState.menuCenter.x,
                            y: state.radialMenuState.menuCenter.y
                        )
                        .transition(.scale(scale: 0.8, anchor: .center).combined(with: .opacity))
                    } else if !state.voiceState.isVoiceUIVisible {
                        // Radial menu (only when not in voice mode)
                        RadialMenuView(
                            state: state.radialMenuState,
                            onRecipeSelected: { recipe in
                                state.hasUserInteraction = true
                                window?.triggerRecipe(recipe)
                            },
                            onSearchSelected: {
                                state.hasUserInteraction = true
                                window?.triggerRecipe(state.radialMenuState.recipes[0])
                            },
                            onSearchSend: { text in
                                state.hasUserInteraction = true
                                window?.triggerCustomPrompt(text)
                            },
                            onUserInteraction: {
                                state.hasUserInteraction = true
                            }
                        )
                        .frame(
                            width: state.radialMenuState.isSearchExpanded ? expandedMenuSize : menuSize,
                            height: state.radialMenuState.isSearchExpanded ? 300 : menuSize
                        )
                        .position(
                            x: state.radialMenuState.menuCenter.x,
                            y: state.radialMenuState.menuCenter.y
                        )
                        .transition(.scale(scale: 0.8, anchor: .center).combined(with: .opacity))

                        if let recipe = hoveredRecipe {
                            BubbleTooltip(label: recipe.label)
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 110)
                                .zIndex(100)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                .animation(.easeInOut(duration: 0.15), value: recipe.id)
                        }
                    }
                }

                // Voice status badge - shows independently when Fn or Fn+Shift held
                if shouldShowVoiceBadge {
                    VoiceStatusBadge(voiceState: state.voiceState)
                        .position(x: geometry.size.width / 2, y: geometry.size.height - 60)
                        .zIndex(200)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.isShowingResponse)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.voiceState.isVoiceUIVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.voiceState.mode)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.voiceState.processingState)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.voiceState.liveStatus)
    }
}
