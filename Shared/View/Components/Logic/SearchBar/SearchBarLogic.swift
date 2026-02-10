import SwiftUI

/// Represents a searchable suggestion with icon
struct SearchSuggestion: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let icon: String

    init(_ label: String, icon: String) {
        self.label = label
        self.icon = icon
    }
}

/// Observable state for SearchBar component
@Observable
final class SearchBarLogic {
    // MARK: - Input State

    var searchText: String = ""
    var isExpanded: Bool = false
    var isHovering: Bool = false
    var isRecording: Bool = false

    // MARK: - Tab Navigation State

    private(set) var tabSuggestionIndex: Int?

    // MARK: - Animation State

    var isIconBouncing: Bool = false
    var canBounceOnHover: Bool = false

    // MARK: - Data

    let suggestions: [SearchSuggestion]

    // MARK: - Computed: Activity State

    var isActive: Bool {
        isHovering || isExpanded || isRecording
    }

    // MARK: - Computed: Layout

    private var spaceCount: Int {
        searchText.filter { $0 == " " }.count
    }

    private var hasMatch: Bool {
        exactMatch != nil || hasActiveAutocompletion
    }

    var isMultiline: Bool {
        if searchText.contains("\n") { return true }
        if searchText.count > 30 { return true }
        if hasMatch { return false }

        let count = searchText.count
        if spaceCount >= 2 && count >= 11 { return true }
        if spaceCount == 0 && count >= 18 { return true }

        return false
    }

    // MARK: - Computed: Icon

    var iconColor: Color {
        if isRecording { return .red }
        if exactMatch != nil || hasActiveAutocompletion {
            return Color(nsColor: .controlTextColor)
        }
        if isHovering {
            return Color(nsColor: .controlTextColor)
        }
        return Color(nsColor: .secondaryLabelColor)
    }

    var currentIcon: String {
        if isRecording { return "waveform.mid" }
        if let match = exactMatch, let suggestion = suggestions.first(where: { $0.label == match }) {
            return suggestion.icon
        }
        if hasActiveAutocompletion, let selected = selectedSuggestion {
            return selected.icon
        }
        return isExpanded ? "waveform.mid" : "space"
    }

    var showsWaveformIcon: Bool {
        currentIcon == "waveform.mid" && !isRecording
    }

    // MARK: - Computed: Suggestions

    var filteredSuggestions: [SearchSuggestion] {
        if searchText.isEmpty, let index = tabSuggestionIndex {
            let startIndex = index % suggestions.count
            return (0 ..< 4).map { i in
                suggestions[(startIndex + i) % suggestions.count]
            }
        }
        if searchText.isEmpty {
            return []
        }
        let trimmed = searchText.lowercased()
        return suggestions
            .filter { $0.label.lowercased().hasPrefix(trimmed) }
            .prefix(3)
            .map { $0 }
    }

    var exactMatch: String? {
        let trimmed = searchText.lowercased()
        return suggestions.first { $0.label.lowercased() == trimmed }?.label
    }

    var orderedSuggestions: [SearchSuggestion] {
        let filtered = filteredSuggestions
        guard !filtered.isEmpty else { return [] }

        if searchText.isEmpty {
            return filtered
        } else {
            let startIndex = tabSuggestionIndex.map { $0 % filtered.count } ?? 0
            return (0 ..< filtered.count).map { i in
                filtered[(startIndex + i) % filtered.count]
            }
        }
    }

    var badgesToDisplay: [SearchSuggestion] {
        guard !orderedSuggestions.isEmpty else { return [] }
        if exactMatch != nil { return [] }

        var result: [SearchSuggestion] = []
        var totalLength = 0
        for badge in orderedSuggestions {
            if totalLength + badge.label.count > 50 {
                break
            }
            result.append(badge)
            totalLength += badge.label.count
        }
        return result
    }

    // MARK: - Computed: Autocompletion

    var selectedSuggestion: SearchSuggestion? {
        orderedSuggestions.first
    }

    var autocompletion: String? {
        guard exactMatch == nil, let selected = selectedSuggestion else { return nil }
        if searchText.isEmpty, tabSuggestionIndex != nil {
            return selected.label
        }
        return String(selected.label.dropFirst(searchText.count))
    }

    var hasActiveAutocompletion: Bool {
        guard let completion = autocompletion else { return false }
        return !completion.isEmpty
    }

    var shouldShowBadges: Bool {
        !badgesToDisplay.isEmpty && hasActiveAutocompletion
    }

    var showPlaceholder: Bool {
        searchText.isEmpty && (autocompletion?.isEmpty ?? true)
    }

    // MARK: - Init

    init(suggestions: [SearchSuggestion]) {
        self.suggestions = suggestions
    }

    // MARK: - Actions

    func startRecording() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isRecording = true
            isExpanded = false
        }
    }

    func stopRecording() {
        withAnimation {
            isRecording = false
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func selectSuggestion(_ suggestion: SearchSuggestion) {
        searchText = suggestion.label
    }

    // MARK: - Tab Navigation

    func handleTab() {
        if searchText.isEmpty {
            if let current = tabSuggestionIndex {
                tabSuggestionIndex = (current + 1) % suggestions.count
            } else {
                tabSuggestionIndex = 0
            }
            return
        }

        guard !filteredSuggestions.isEmpty else { return }

        if filteredSuggestions.count == 1 {
            searchText = filteredSuggestions[0].label
            resetTabState()
            return
        }

        if let current = tabSuggestionIndex {
            tabSuggestionIndex = (current + 1) % filteredSuggestions.count
        } else {
            tabSuggestionIndex = 1
        }
    }

    func resetTabState() {
        tabSuggestionIndex = nil
    }

    func handleSearchTextChange(oldValue: String, newValue: String) {
        if !newValue.isEmpty, oldValue.isEmpty {
            resetTabState()
        }
    }

    // MARK: - Hover

    func updateHover(_ hovering: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isHovering = hovering
        }
        if showsWaveformIcon, canBounceOnHover {
            isIconBouncing = hovering
        }
    }

    func enableBounceOnHover() async {
        canBounceOnHover = false
        try? await Task.sleep(for: .milliseconds(500))
        canBounceOnHover = true
    }

    func disableBounceOnHover() {
        canBounceOnHover = false
    }

    // MARK: - Keyboard and Icon actions

    enum IconTapResult {
        case startedRecording
        case stoppedRecording
        case expanded
        case shouldSend
        case noAction
    }

    func handleIconTap() -> IconTapResult {
        if showsWaveformIcon {
            startRecording()
            return .startedRecording
        }

        if isRecording {
            stopRecording()
            return .stoppedRecording
        }

        if !isExpanded {
            withAnimation {
                isExpanded = true
            }
            return .expanded
        }

        if exactMatch != nil || hasActiveAutocompletion {
            return .shouldSend
        }

        return .noAction
    }

    // Used by multiline input action to start recording and trigger a bounce shortly after.
    func handleMultilineRecordTap() async {
        startRecording()
        // Trigger bounce after transition (similar to preview behavior)
        try? await Task.sleep(for: .milliseconds(100))
        isIconBouncing.toggle()
    }

    // MARK: - Send Actions

    enum SendSource: String {
        case returnKey = "Return key"
        case sendButton = "Send button"
        case bubbleClick = "Bubble click"
    }

    func prepareSend(source: SendSource) -> String {
        let finalText: String
        if let completion = autocompletion, !completion.isEmpty {
            finalText = searchText + completion
        } else {
            finalText = searchText
        }

        print("[SearchBar] Send via \(source.rawValue)")
        print("[SearchBar]   searchText: \"\(searchText)\"")
        print("[SearchBar]   autocompletion: \"\(autocompletion ?? "nil")\"")
        print("[SearchBar]   finalText: \"\(finalText)\"")
        print("[SearchBar]   isMultiline: \(isMultiline)")
        print("[SearchBar]   selectedSuggestion: \(selectedSuggestion?.label ?? "nil")")

        return finalText
    }
}
