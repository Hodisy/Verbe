import SwiftUI

@Observable
class SettingsViewModel {
    var geminiApiKey: String = ""
    var liveVoicePrompt: String = ""
    var voiceCommandPrompt: String = ""
    var customRecipes: [Recipe] = []

    static let liveVoicePromptKey = "live_voice_prompt"
    static let voiceCommandPromptKey = "voice_command_prompt"

    static let defaultLiveVoicePrompt = """
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
    """

    static let defaultVoiceCommandPrompt = """
    You are a precise command-to-text drafting engine.

    Rules:
    1. Analyze the audio command.
    2. If "Selected Text" exists, perform an EDIT on it (rewrite, translate, etc.).
    3. If no "Selected Text", perform a CREATE action (write new message).
    4. You MUST NOT ask questions. Make the best reasonable default assumptions (e.g., neutral tone if unspecified, short length).
    5. If critical info is missing (like a time), use a placeholder like "[time]".
    6. Output JSON with the 'intent' details and the final 'form' text.
    """

    init() {
        loadApiKey()
        loadLiveVoicePrompt()
        loadVoiceCommandPrompt()
        loadRecipes()
    }

    func saveApiKey() {
        UserDefaults.standard.set(geminiApiKey, forKey: "gemini_api_key")
    }

    func loadApiKey() {
        geminiApiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
    }

    func saveLiveVoicePrompt() {
        UserDefaults.standard.set(liveVoicePrompt, forKey: Self.liveVoicePromptKey)
    }

    func loadLiveVoicePrompt() {
        liveVoicePrompt = UserDefaults.standard.string(forKey: Self.liveVoicePromptKey) ?? ""
    }

    func resolvedLiveVoicePrompt() -> String {
        liveVoicePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.defaultLiveVoicePrompt : liveVoicePrompt
    }

    func saveVoiceCommandPrompt() {
        UserDefaults.standard.set(voiceCommandPrompt, forKey: Self.voiceCommandPromptKey)
    }

    func loadVoiceCommandPrompt() {
        voiceCommandPrompt = UserDefaults.standard.string(forKey: Self.voiceCommandPromptKey) ?? ""
    }

    func resolvedVoiceCommandPrompt() -> String {
        voiceCommandPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.defaultVoiceCommandPrompt : voiceCommandPrompt
    }

    func saveRecipes() {
        if let data = try? JSONEncoder().encode(customRecipes) {
            UserDefaults.standard.set(data, forKey: "custom_recipes")
        }
    }

    func loadRecipes() {
        if let data = UserDefaults.standard.data(forKey: "custom_recipes"),
           let recipes = try? JSONDecoder().decode([Recipe].self, from: data) {
            customRecipes = recipes
        }
    }

    func addRecipe(_ recipe: Recipe) {
        customRecipes.append(recipe)
        saveRecipes()
    }

    func deleteRecipe(at index: Int) {
        customRecipes.remove(at: index)
        saveRecipes()
    }

    func updateRecipe(at index: Int, with recipe: Recipe) {
        customRecipes[index] = recipe
        saveRecipes()
    }

    func moveRecipe(from source: IndexSet, to destination: Int) {
        customRecipes.move(fromOffsets: source, toOffset: destination)
        saveRecipes()
    }

    func populateDefaultRecipes() {
        customRecipes = Self.defaultRecipes
        saveRecipes()
    }

    func deleteAllRecipes() {
        customRecipes.removeAll()
        saveRecipes()
    }

    func reloadAllRecipes() {
        populateDefaultRecipes()
    }

    static let defaultRecipes: [Recipe] = [
        Recipe(
            icon: "envelope",
            label: "Mailer",
            systemPrompt: "Write a professional email (4-6 lines max) from the input text, reformulate it and make it clear, concise, strong call to action, your output need just be the email ready to send, nothing else, the email is signed by Yafa, and write in same language of the input. Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.5, green: 0.53, blue: 0.97),
            glow: Color(red: 0.39, green: 0.4, blue: 0.95),
            isCustom: true
        ),
        Recipe(
            icon: "textformat",
            label: "Tonify",
            systemPrompt: "Make the text friendlier and more engaging (4-6 lines max), same meaning. Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.13, green: 0.83, blue: 0.93),
            glow: Color(red: 0.13, green: 0.83, blue: 0.93),
            isCustom: true
        ),
        Recipe(
            icon: "doc.text",
            label: "Summarizer",
            systemPrompt: "Summarize key points in bullet form (4-6 lines max total). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.98, green: 0.75, blue: 0.14),
            glow: Color(red: 0.98, green: 0.75, blue: 0.14),
            isCustom: true
        ),
        Recipe(
            icon: "sparkles.rectangle.stack",
            label: "Clean Up",
            systemPrompt: """
            Return exactly this text and nothing else:
            ## The Problem
            Pizzas are round. Boxes are square.
            This mismatch has persisted since 1966 (Domino's patent).

            ## Why It Still Exists
            Original reason: cardboard cost savings.
            Current reality: cardboard is cheap. Inertia is expensive.

            ## Proposed Solution
            Origami-fold box: starts flat/square, unfolds into circle.
            No cutting waste. Premium unboxing experience.
            """,
            color: Color(red: 0.96, green: 0.62, blue: 0.27),
            glow: Color(red: 0.96, green: 0.62, blue: 0.27),
            isCustom: true
        ),
        Recipe(
            icon: "list.bullet.indent",
            label: "Outliner",
            systemPrompt: "Convert into a clear outline with headings and bullets (4-6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.38, green: 0.65, blue: 0.98),
            glow: Color(red: 0.38, green: 0.65, blue: 0.98),
            isCustom: true
        ),
        Recipe(
            icon: "megaphone",
            label: "Marketer",
            systemPrompt: "Rewrite as punchy marketing copy focused on benefits and urgency (4-6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.91, green: 0.47, blue: 0.98),
            glow: Color(red: 0.91, green: 0.47, blue: 0.98),
            isCustom: true
        ),
        Recipe(
            icon: "graduationcap",
            label: "Explainify",
            systemPrompt: "Explain simply in plain language in french even if input is not in french, short examples if useful (4-6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.64, green: 0.9, blue: 0.21),
            glow: Color(red: 0.64, green: 0.9, blue: 0.21),
            isCustom: true
        ),
        Recipe(
            icon: "sparkles",
            label: "Creatify",
            systemPrompt: "Rewrite creatively with vivid imagery and fresh perspective (4-6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.75, green: 0.52, blue: 0.99),
            glow: Color(red: 0.75, green: 0.52, blue: 0.99),
            isCustom: true
        ),
        Recipe(
            icon: "number",
            label: "Datify",
            systemPrompt: "Extract structured, data-driven insights or metrics (4-6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.58, green: 0.64, blue: 0.72),
            glow: Color(red: 0.58, green: 0.64, blue: 0.72),
            isCustom: true
        ),
        Recipe(
            icon: "globe.europe.africa",
            label: "Translate to French",
            systemPrompt: "Fully translate into French. Preserve meaning and tone. Output only the translation text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.0, green: 0.48, blue: 0.8),
            glow: Color(red: 0.0, green: 0.48, blue: 0.8),
            isCustom: true
        ),
        Recipe(
            icon: "globe.asia.australia",
            label: "Translate to Japanese",
            systemPrompt: "Fully translate into Japanese. Preserve meaning and tone. Output only the translation text. No Markdown, no quotes, and no intro/outro text. Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.85, green: 0.25, blue: 0.35),
            glow: Color(red: 0.85, green: 0.25, blue: 0.35),
            isCustom: true
        ),
        Recipe(
            icon: "globe.americas",
            label: "Translate to English",
            systemPrompt: "Fully translate into English. Preserve meaning and tone. Output only the translation text. No Markdown, no quotes, and no intro/outro text. Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.2, green: 0.6, blue: 0.4),
            glow: Color(red: 0.2, green: 0.6, blue: 0.4),
            isCustom: true
        ),
        Recipe(
            icon: "text.word.spacing",
            label: "Simplify",
            systemPrompt: "Rewrite in simpler words. Remove jargon. Short sentences. Same meaning. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.4, green: 0.75, blue: 0.65),
            glow: Color(red: 0.4, green: 0.75, blue: 0.65),
            isCustom: true
        ),
        Recipe(
            icon: "textformat.abc",
            label: "Fix Grammar",
            systemPrompt: "Correct grammar, spelling, and punctuation. Do not rephrase unless necessary. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.95, green: 0.45, blue: 0.45),
            glow: Color(red: 0.95, green: 0.45, blue: 0.45),
            isCustom: true
        ),
        Recipe(
            icon: "arrow.down.left.and.arrow.up.right",
            label: "Shorten",
            systemPrompt: "Condense the text as much as possible without losing meaning. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.55, green: 0.55, blue: 0.85),
            glow: Color(red: 0.55, green: 0.55, blue: 0.85),
            isCustom: true
        ),
        Recipe(
            icon: "arrow.up.left.and.arrow.down.right",
            label: "Expand",
            systemPrompt: "Expand slightly with useful details and clarity, no fluff. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.7, green: 0.85, blue: 0.5),
            glow: Color(red: 0.7, green: 0.85, blue: 0.5),
            isCustom: true
        ),
        Recipe(
            icon: "checklist",
            label: "Actionify",
            systemPrompt: "Rewrite as clear, actionable steps or instructions. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.3, green: 0.7, blue: 0.9),
            glow: Color(red: 0.3, green: 0.7, blue: 0.9),
            isCustom: true
        ),
        Recipe(
            icon: "text.badge.plus",
            label: "Add Examples",
            systemPrompt: "Rewrite the text and add 2-4 concrete examples that make the idea easier to understand. Keep the original meaning and tone. Output only the rewritten text.",
            color: Color(red: 0.88, green: 0.58, blue: 0.34),
            glow: Color(red: 0.88, green: 0.58, blue: 0.34),
            isCustom: true
        ),
        Recipe(
            icon: "wand.and.stars",
            label: "Polish",
            systemPrompt: "Improve clarity, flow, and tone. Keep it professional and sharp. (4–6 lines max) Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.85, green: 0.65, blue: 0.95),
            glow: Color(red: 0.85, green: 0.65, blue: 0.95),
            isCustom: true
        ),
        Recipe(
            icon: "list.bullet",
            label: "Bulletize",
            systemPrompt: "Convert the text into concise bullet points only. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.5, green: 0.7, blue: 0.8),
            glow: Color(red: 0.5, green: 0.7, blue: 0.8),
            isCustom: true
        ),
        Recipe(
            icon: "textformat.size",
            label: "Title Generator",
            systemPrompt: "Generate a strong, clear title capturing the core idea. (1 line). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.95, green: 0.6, blue: 0.3),
            glow: Color(red: 0.95, green: 0.6, blue: 0.3),
            isCustom: true
        ),
        Recipe(
            icon: "hand.point.right",
            label: "CTAify",
            systemPrompt: "Add or rewrite a compelling call to action. Clear and direct. (1–2 lines). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.9, green: 0.35, blue: 0.5),
            glow: Color(red: 0.9, green: 0.35, blue: 0.5),
            isCustom: true
        ),
        Recipe(
            icon: "shield",
            label: "Objection Handler",
            systemPrompt: "Rewrite to address common objections or doubts proactively. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.45, green: 0.55, blue: 0.7),
            glow: Color(red: 0.45, green: 0.55, blue: 0.7),
            isCustom: true
        ),
        Recipe(
            icon: "person.2",
            label: "Persona Shift",
            systemPrompt: "Rewrite for the specified audience or persona. Adapt tone and language. (4–6 lines max). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.6, green: 0.45, blue: 0.8),
            glow: Color(red: 0.6, green: 0.45, blue: 0.8),
            isCustom: true
        ),
        Recipe(
            icon: "text.justify.left",
            label: "TL;DR",
            systemPrompt: "Provide a very short TL;DR summary of the text. (1–2 lines). Output only the transformed text. No Markdown, no quotes, and no intro/outro text.",
            color: Color(red: 0.75, green: 0.75, blue: 0.4),
            glow: Color(red: 0.75, green: 0.75, blue: 0.4),
            isCustom: true
        ),
        Recipe(
            icon: "tablecells",
            label: "Tablify",
            systemPrompt: "Structure the content into a clean, compact Markdown table suitable for Notion. Clear headers, concise cells. (4–6 rows)",
            color: Color(red: 0.25, green: 0.85, blue: 0.55),
            glow: Color(red: 0.25, green: 0.85, blue: 0.55),
            isCustom: true
        ),
        Recipe(
            icon: "doc.text.magnifyingglass",
            label: "File Summary",
            systemPrompt: "You are analyzing a file selected in Finder. Provide: 1) A brief summary (2-3 sentences), 2) File type and purpose, 3) Key highlights or patterns, 4) Any notable issues or recommendations. Be concise and helpful.",
            color: Color(red: 0.4, green: 0.6, blue: 0.95),
            glow: Color(red: 0.4, green: 0.6, blue: 0.95),
            isCustom: true
        ),
        Recipe(
            icon: "eye",
            label: "Analyze Screen",
            systemPrompt: "You are a visual analysis assistant. Analyze the screenshot and provide: 1) A description of what you see, 2) Key elements and their purpose, 3) Any issues or suggestions. Be concise and helpful.",
            color: Color(red: 0.3, green: 0.8, blue: 0.7),
            glow: Color(red: 0.3, green: 0.8, blue: 0.7),
            isCustom: true,
            isVisionRecipe: true
        ),
        Recipe(
            icon: "exclamationmark.triangle",
            label: "Scam Detector",
            systemPrompt: "You are a security expert analyzing a screenshot for potential scams or phishing attempts. Look for: 1) Suspicious URLs or email addresses, 2) Urgency tactics or threats, 3) Grammar/spelling errors typical of scams, 4) Requests for sensitive information, 5) Brand impersonation attempts. Provide a clear verdict: LEGITIMATE, SUSPICIOUS, or LIKELY SCAM with detailed reasoning.",
            color: Color(red: 0.95, green: 0.3, blue: 0.3),
            glow: Color(red: 0.95, green: 0.3, blue: 0.3),
            isCustom: true,
            isVisionRecipe: true
        ),
        Recipe(
            icon: "paintbrush",
            label: "Design Review",
            systemPrompt: "You are a UX/UI design expert. Analyze this design screenshot and provide: 1) Overall design assessment, 2) Usability issues, 3) Visual hierarchy problems, 4) Accessibility concerns, 5) Specific improvement suggestions. Be constructive and actionable.",
            color: Color(red: 0.9, green: 0.5, blue: 0.8),
            glow: Color(red: 0.9, green: 0.5, blue: 0.8),
            isCustom: true,
            isVisionRecipe: true
        ),
        Recipe(
            icon: "photo.badge.plus",
            label: "Generate Image",
            systemPrompt: "Generate an image of:",
            color: Color(red: 0.6, green: 0.4, blue: 0.9),
            glow: Color(red: 0.6, green: 0.4, blue: 0.9),
            isCustom: true,
            isImageGenRecipe: true
        ),
        Recipe(
            icon: "face.smiling",
            label: "Memify",
            systemPrompt: "Generate a funny meme image based on:",
            color: Color(red: 0.98, green: 0.71, blue: 0.2),
            glow: Color(red: 0.98, green: 0.71, blue: 0.2),
            isCustom: true,
            isImageGenRecipe: true
        ),
    ]
}
