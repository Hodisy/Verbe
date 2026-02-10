import SwiftUI

/// Search bar with glass effect, autocompletion, and suggestion badges
/// Pure composition - no inline logic, only sub-components
struct SearchBarView: View {
    @Bindable var state: SearchBarLogic
    @FocusState private var isTextFieldFocused: Bool
    @Namespace private var namespace

    var onSend: (_ text: String, _ source: SearchBarLogic.SendSource) -> Void = { _, _ in }

    var body: some View {
        // GlassEffectContainer(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                if state.isExpanded && state.shouldShowBadges && !state.isMultiline {
                    SuggestionBadgesRow(
                        suggestions: state.badgesToDisplay,
                        onSelect: state.selectSuggestion
                    )
                }

                HStack(alignment: .bottom, spacing: 12) {
                    if !state.isMultiline || state.isRecording {
                        GlassIconButton(
                            icon: state.currentIcon,
                            size: state.isHovering ? 38 : (state.isActive ? 48 : 32),
                            iconSize: 24,
                            iconColor: state.iconColor,
                            iconScale: state.hasActiveAutocompletion ? 0.7 : (state.isActive ? (state.isHovering ? 0.8 : 1) : 0.7),
                            isBouncing: state.isIconBouncing,
                            isRepeatingBounce: state.isRecording,
                            // glassID: "ellipsis",
                            namespace: namespace,
                            onTap: {
                                let result = state.handleIconTap()
                                switch result {
                                case .expanded:
                                    isTextFieldFocused = true
                                case .shouldSend:
                                    let text = state.prepareSend(source: .bubbleClick)
                                    onSend(text, .bubbleClick)
                                case .startedRecording, .stoppedRecording, .noAction:
                                    break
                                }
                            }
                        )
                        .offset(x: state.isRecording ? 0 : 0)
                        .task(id: state.isExpanded) {
                            if state.isExpanded {
                                await state.enableBounceOnHover()
                            } else {
                                state.disableBounceOnHover()
                            }
                        }
                        .onHover { hovering in
                            state.updateHover(hovering)
                        }
                    }

                    if state.isExpanded && !state.isRecording {
                        SearchInputField(
                            text: $state.searchText,
                            isFocused: $isTextFieldFocused,
                            autocompletion: state.autocompletion,
                            showPlaceholder: state.showPlaceholder,
                            isMultiline: state.isMultiline,
                            glassID: "search",
                            namespace: namespace,
                            onTab: state.handleTab,
                            onSendViaReturn: {
                                let text = state.prepareSend(source: .returnKey)
                                onSend(text, .returnKey)
                            },
                            onSendViaButton: {
                                let text = state.prepareSend(source: .sendButton)
                                onSend(text, .sendButton)
                            },
                            onResetTabState: state.resetTabState,
                            onRecordTap: {
                                Task {
                                    await state.handleMultilineRecordTap()
                                }
                            }
                        )
                    }
                }
            // }
        }
        .animation(.easeInOut(duration: 0.2), value: state.filteredSuggestions.map(\.id))
        .animation(.easeInOut(duration: 0.2), value: state.exactMatch)
        .animation(.easeInOut(duration: 0.2), value: state.isMultiline)
        .animation(.easeInOut(duration: 0.2), value: state.tabSuggestionIndex)
        .onChange(of: state.searchText) { oldValue, newValue in
            state.handleSearchTextChange(oldValue: oldValue, newValue: newValue)
        }
    }
}
