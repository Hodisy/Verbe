import SwiftUI


public struct RadialMenuView: View {
    public let state: RadialMenuState
    public let onRecipeSelected: (Recipe) -> Void
    public let onSearchSelected: () -> Void
    public var onSearchSend: ((String) -> Void)?
    public var onUserInteraction: (() -> Void)?

    @State var state2: SearchBarLogic

    @Namespace private var searchNamespace

    public init(
        state: RadialMenuState,
        onRecipeSelected: @escaping (Recipe) -> Void,
        onSearchSelected: @escaping () -> Void,
        onSearchSend: ((String) -> Void)? = nil,
        onUserInteraction: (() -> Void)? = nil
    ) {
        self.state = state
        self.onRecipeSelected = onRecipeSelected
        self.onSearchSelected = onSearchSelected
        self.onSearchSend = onSearchSend
        self.onUserInteraction = onUserInteraction

        let suggestions = state.recipes.map { SearchSuggestion($0.label, icon: $0.icon) }
        self._state2 = State(initialValue: SearchBarLogic(suggestions: suggestions))
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !state2.isExpanded {
                    ForEach(0 ..< state.maxBubbles, id: \.self) { slot in
                        let recipe = state.recipeAt(slot: slot)
                        let isHovered = state.hoveredIndex == slot

                        LiquidBubbleView(
                            recipe: recipe,
                            isHovered: isHovered
                        )
                        .scaleEffect(state.bubbleScale(for: slot))
                        .opacity(state.bubbleOpacity(for: slot))
                        .rotationEffect(.degrees(state.bubbleRotation(for: slot)))
                        .offset(state.bubbleOffset(for: slot))
                        .onTapGesture {
                            onRecipeSelected(recipe)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .center)))
                        .animation(.easeInOut(duration: 0.15), value: isHovered)
                    }
                }

                // GlassEffectContainer(spacing: 20.0) {
                    SearchBarView(state: state2, onSend: { text, _ in
                        handleSearchSend(text)
                    })
                // }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.2), value: state2.isExpanded)
            .onChange(of: state2.isExpanded) { _, isExpanded in
                state.isSearchExpanded = isExpanded
                if isExpanded {
                    onUserInteraction?()
                }
            }
            .onChange(of: state.isSearchExpanded) { _, isExpanded in
                if isExpanded && !state2.isExpanded {
                    withAnimation {
                        state2.isExpanded = true
                    }
                }
            }
        }
    }

    private func handleSearchSend(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Match against recipe labels (case-insensitive)
        if let recipe = state.recipes.first(where: { $0.label.lowercased() == trimmed.lowercased() }) {
            onRecipeSelected(recipe)
        } else {
            // No recipe match — use text as custom prompt
            onSearchSend?(trimmed)
        }
    }
}
