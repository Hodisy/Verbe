import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct RecipeEditorView: View {
    let recipe: Recipe?
    @Bindable var viewModel: SettingsViewModel
    @Binding var isPresented: Bool

    @State private var label: String
    @State private var icon: String
    @State private var intent: String
    @State private var color: Color
    @State private var glow: Color
    @State private var isVisionRecipe: Bool
    @State private var isImageGenRecipe: Bool
    @State private var iconPage: Int

    private static let visibleIconsPerPage = 15
    private static let iconCatalog: [String] = {
        let baseIcons = [
            "star", "sparkles", "wand.and.stars", "magicmouse", "paintbrush", "pencil", "scribble", "lasso", "highlighter",
            "textformat", "textformat.abc", "text.word.spacing", "text.justify.left", "text.justify", "doc.text", "doc.richtext",
            "doc.plaintext", "doc.text.magnifyingglass", "note.text", "list.bullet", "list.bullet.indent", "list.number", "checklist",
            "quote.bubble", "character.cursor.ibeam", "paragraphsign", "arrow.up.and.down.text.horizontal",
            "envelope", "paperplane", "tray", "tray.and.arrow.down", "tray.and.arrow.up", "bookmark", "book", "books.vertical",
            "megaphone", "mic", "waveform", "speaker.wave.2", "headphones", "person", "person.2", "person.crop.circle",
            "person.text.rectangle", "person.crop.square", "person.badge.plus", "person.badge.shield.checkmark",
            "graduationcap", "brain.head.profile", "lightbulb", "bolt", "flame", "leaf", "target", "scope", "shield",
            "lock", "lock.shield", "key", "eye", "eyes", "binoculars", "camera", "photo", "photo.badge.plus", "video",
            "magnifyingglass", "magnifyingglass.circle", "globe", "globe.americas", "globe.europe.africa", "globe.asia.australia",
            "map", "map.fill", "location", "mappin", "flag", "bell", "bell.badge", "clock", "timer", "calendar",
            "chart.bar", "chart.line.uptrend.xyaxis", "chart.pie", "number", "sum", "percent", "function", "tablecells",
            "square.grid.2x2", "square.grid.3x3", "square.and.pencil", "rectangle.and.pencil.and.ellipsis", "keyboard",
            "command", "option", "shift", "return", "delete.left", "escape", "capslock", "folder", "folder.badge.plus",
            "externaldrive", "internaldrive", "desktopcomputer", "laptopcomputer", "macwindow", "display", "cpu", "memorychip",
            "network", "wifi", "antenna.radiowaves.left.and.right", "icloud", "server.rack", "terminal", "curlybraces",
            "chevron.left.forwardslash.chevron.right", "hammer", "wrench", "gear", "gearshape", "slider.horizontal.3",
            "switch.2", "app", "apps.iphone", "window.shade.open", "window.vertical.open", "square.3.layers.3d",
            "cube", "shippingbox", "archivebox", "link", "paperclip", "pin", "tag", "scissors", "trash",
            "arrow.clockwise", "arrow.counterclockwise", "arrow.triangle.2.circlepath", "arrow.left.and.right", "arrow.up.and.down",
            "arrow.turn.down.left", "arrow.uturn.backward", "arrow.uturn.forward", "arrowshape.turn.up.left", "arrowshape.turn.up.right",
            "checkmark.circle", "xmark.circle", "exclamationmark.triangle", "questionmark.circle", "info.circle",
            "hand.point.right", "hand.thumbsup", "hand.thumbsdown", "hand.raised", "hand.wave", "hand.tap", "gift",
            "cart", "bag", "creditcard", "dollarsign.circle", "eurosign.circle", "yensign.circle", "sterlingsign.circle",
            "building.2", "briefcase", "case", "newspaper", "newspaper.circle", "signature", "ticket", "medal",
            "heart", "heart.text.square", "face.smiling", "sun.max", "moon", "cloud", "snowflake", "drop", "bolt.circle",
            "tortoise", "hare", "car", "airplane", "ferry", "tram", "bicycle", "figure.walk", "figure.run",
            "music.note", "play.circle", "pause.circle", "stop.circle", "record.circle", "headphones.circle"
        ]
        let variants = ["", ".fill", ".circle", ".circle.fill", ".square", ".square.fill"]
        var seen = Set<String>()
        var icons: [String] = []

        for base in baseIcons {
            for variant in variants {
                let candidate = "\(base)\(variant)"
                guard seen.insert(candidate).inserted else { continue }
                guard Self.isValidSymbol(candidate) else { continue }
                icons.append(candidate)
                if icons.count == 255 { return icons }
            }
        }

        var fallbackIndex = 0
        while icons.count < 255 {
            icons.append(baseIcons[fallbackIndex % baseIcons.count])
            fallbackIndex += 1
        }

        return Array(icons.prefix(255))
    }()

    private static let colorGlowPresets: [ColorGlowPreset] = [
        .init(color: Color(red: 0.50, green: 0.53, blue: 0.97), glow: Color(red: 0.39, green: 0.40, blue: 0.95)),
        .init(color: Color(red: 0.13, green: 0.83, blue: 0.93), glow: Color(red: 0.13, green: 0.83, blue: 0.93)),
        .init(color: Color(red: 0.98, green: 0.75, blue: 0.14), glow: Color(red: 0.98, green: 0.75, blue: 0.14)),
        .init(color: Color(red: 0.38, green: 0.65, blue: 0.98), glow: Color(red: 0.38, green: 0.65, blue: 0.98)),
        .init(color: Color(red: 0.91, green: 0.47, blue: 0.98), glow: Color(red: 0.91, green: 0.47, blue: 0.98)),
        .init(color: Color(red: 0.64, green: 0.90, blue: 0.21), glow: Color(red: 0.64, green: 0.90, blue: 0.21)),
        .init(color: Color(red: 0.75, green: 0.52, blue: 0.99), glow: Color(red: 0.75, green: 0.52, blue: 0.99)),
        .init(color: Color(red: 0.58, green: 0.64, blue: 0.72), glow: Color(red: 0.58, green: 0.64, blue: 0.72)),
        .init(color: Color(red: 0.00, green: 0.48, blue: 0.80), glow: Color(red: 0.00, green: 0.48, blue: 0.80)),
        .init(color: Color(red: 0.85, green: 0.25, blue: 0.35), glow: Color(red: 0.85, green: 0.25, blue: 0.35)),
        .init(color: Color(red: 0.20, green: 0.60, blue: 0.40), glow: Color(red: 0.20, green: 0.60, blue: 0.40)),
        .init(color: Color(red: 0.95, green: 0.45, blue: 0.45), glow: Color(red: 0.95, green: 0.45, blue: 0.45)),
        .init(color: Color(red: 0.40, green: 0.75, blue: 0.65), glow: Color(red: 0.40, green: 0.75, blue: 0.65)),
        .init(color: Color(red: 0.90, green: 0.35, blue: 0.50), glow: Color(red: 0.90, green: 0.35, blue: 0.50)),
        .init(color: Color(red: 0.25, green: 0.85, blue: 0.55), glow: Color(red: 0.25, green: 0.85, blue: 0.55)),
        .init(color: Color(red: 0.60, green: 0.40, blue: 0.90), glow: Color(red: 0.60, green: 0.40, blue: 0.90))
    ]

    init(recipe: Recipe?, viewModel: SettingsViewModel, isPresented: Binding<Bool>) {
        self.recipe = recipe
        self.viewModel = viewModel
        self._isPresented = isPresented

        let initialIcon = recipe?.icon ?? "star.fill"
        let initialPage = (Self.iconCatalog.firstIndex(of: initialIcon) ?? 0) / Self.visibleIconsPerPage

        _label = State(initialValue: recipe?.label ?? "")
        _icon = State(initialValue: initialIcon)
        _intent = State(initialValue: recipe?.systemPrompt ?? "")
        _color = State(initialValue: recipe?.color ?? .blue)
        _glow = State(initialValue: recipe?.glow ?? .blue)
        _isVisionRecipe = State(initialValue: recipe?.isVisionRecipe ?? false)
        _isImageGenRecipe = State(initialValue: recipe?.isImageGenRecipe ?? false)
        _iconPage = State(initialValue: initialPage)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(recipe == nil ? "New Recipe" : "Edit Recipe")
                        .font(.title2)
                        .bold()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipe Name")
                            .font(.headline)

                        HStack(alignment: .center, spacing: 10) {
                            TextField("Recipe Name", text: $label)
                                .textFieldStyle(.roundedBorder)

                            HStack(spacing: 10) {
                                Toggle("Vision", isOn: $isVisionRecipe)
                                    .toggleStyle(.checkbox)
                                    .controlSize(.small)
                                    .onChange(of: isVisionRecipe) { _, enabled in
                                        if enabled { isImageGenRecipe = false }
                                    }

                                Toggle("Image Gen", isOn: $isImageGenRecipe)
                                    .toggleStyle(.checkbox)
                                    .controlSize(.small)
                                    .onChange(of: isImageGenRecipe) { _, enabled in
                                        if enabled { isVisionRecipe = false }
                                    }
                            }
                            .fixedSize()
                            .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.headline)
                        Text("Choose one icon. Tap the reload tile to see more.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 32, maximum: 56), spacing: 8), count: 8), spacing: 8) {
                            ForEach(Array(currentIconPageItems.enumerated()), id: \.offset) { _, symbolName in
                                Button {
                                    icon = symbolName
                                } label: {
                                    Image(systemName: symbolName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 36, height: 36)
                                        .foregroundColor(icon == symbolName ? .white : Semantics.textPrimary)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(icon == symbolName ? Semantics.interactive : Semantics.neutralBackground)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                iconPage = (iconPage + 1) % iconPageCount
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("\(iconPage + 1)/\(iconPageCount)")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .frame(width: 36, height: 36)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.7))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color + Glow")
                            .font(.headline)
                        Text("Pick one combined style.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 40, maximum: 80), spacing: 10), count: 8), spacing: 10) {
                            ForEach(Self.colorGlowPresets) { preset in
                                Button {
                                    color = preset.color
                                    glow = preset.glow
                                } label: {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [preset.glow, preset.color],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.85), lineWidth: isSelected(preset: preset) ? 3 : 0)
                                        )
                                        .frame(width: 28, height: 28)
                                        .shadow(color: preset.glow.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipe Prompt")
                            .font(.headline)
                        ZStack(alignment: .topLeading) {
                            if intent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Describe what this recipe should do...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                            }
                            TextEditor(text: $intent)
                                .font(.body)
                                .frame(minHeight: 120)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(20)
            }

            Divider()
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Save") {
                    saveRecipe()
                }
                .keyboardShortcut(.return)
                .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || intent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(minWidth: 760, minHeight: 680)
    }

    private func saveRecipe() {
        let newRecipe = Recipe(
            id: recipe?.id ?? UUID(),
            icon: icon,
            label: label,
            systemPrompt: intent,
            color: color,
            glow: glow,
            isCustom: true,
            isVisionRecipe: isVisionRecipe,
            isImageGenRecipe: isImageGenRecipe
        )

        if let recipe = recipe, let index = viewModel.customRecipes.firstIndex(where: { $0.id == recipe.id }) {
            viewModel.updateRecipe(at: index, with: newRecipe)
        } else {
            viewModel.addRecipe(newRecipe)
        }

        isPresented = false
    }

    private var iconPageCount: Int {
        max(1, Int(ceil(Double(Self.iconCatalog.count) / Double(Self.visibleIconsPerPage))))
    }

    private var currentIconPageItems: [String] {
        let start = min(iconPage * Self.visibleIconsPerPage, max(0, Self.iconCatalog.count - 1))
        let end = min(start + Self.visibleIconsPerPage, Self.iconCatalog.count)
        return Array(Self.iconCatalog[start..<end])
    }

    private func isSelected(preset: ColorGlowPreset) -> Bool {
        color.toHex() == preset.color.toHex() && glow.toHex() == preset.glow.toHex()
    }

    private static func isValidSymbol(_ name: String) -> Bool {
        #if os(macOS)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #elseif canImport(UIKit)
        return UIImage(systemName: name) != nil
        #else
        return true
        #endif
    }
}

private struct ColorGlowPreset: Identifiable {
    let id: String
    let color: Color
    let glow: Color

    init(color: Color, glow: Color) {
        self.color = color
        self.glow = glow
        id = "\(color.toHex())_\(glow.toHex())"
    }
}
