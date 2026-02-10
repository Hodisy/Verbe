import AppKit
import Foundation

final class FinderService {
    static let shared = FinderService()

    private init() {}

    func isFrontmostAppFinder() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        return frontApp.bundleIdentifier == "com.apple.finder"
    }

    func getSelectedFileInfo() -> String? {
        guard isFrontmostAppFinder() else { return nil }

        guard let selectedURLs = getFinderSelection(), !selectedURLs.isEmpty else {
            print("📁 No files selected in Finder")
            return "No file selected in Finder"
        }

        print("📁 Found \(selectedURLs.count) file(s) selected in Finder")

        if selectedURLs.count > 1 {
            let fileList = selectedURLs.map { "- \($0.lastPathComponent)" }.joined(separator: "\n")
            return "Multiple files selected:\n\(fileList)\n\nPlease select a single file to summarize."
        }

        let url = selectedURLs[0]
        let fileName = url.lastPathComponent
        let filePath = url.path

        guard let content = readFileContent(at: url) else {
            return """
            File: \(fileName)
            Path: \(filePath)

            [Unable to read this file type or file is too large]
            """
        }

        return """
        File: \(fileName)
        Path: \(filePath)

        Content:
        \(content)
        """
    }

    // MARK: - Finder Selection (Accessibility API)

    private func getFinderSelection() -> [URL]? {
        // Strategy 1: Accessibility API (uses existing AX permission, no Apple Events needed)
        if let urls = getFinderSelectionViaAX(), !urls.isEmpty {
            print("✅ Got Finder selection via AX API")
            return urls
        }

        // Strategy 2: AppleScript fallback (needs Automation permission)
        print("🔄 AX API returned nothing, trying AppleScript...")
        if let urls = getFinderSelectionViaAppleScript() {
            return urls
        }

        return nil
    }

    private func getFinderSelectionViaAX() -> [URL]? {
        print("🔍 Trying AX API for Finder selection...")
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier == "com.apple.finder" else { return nil }

        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Wake up the AX tree
        var attributeNames: CFArray?
        AXUIElementCopyAttributeNames(appRef, &attributeNames)

        // Strategy A: Walk up from focused element (works for all Finder views)
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success {
            print("🔍 AX: Got focused element, walking up...")
            let focused = focusedRef as! AXUIElement
            if let urls = findSelectedURLsWalkingUp(from: focused), !urls.isEmpty {
                return urls
            }
        } else {
            print("🚨 AX: Could not get focused element")
        }

        // Strategy B: Search all windows top-down
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            print("🔍 AX: Searching \(windows.count) window(s) top-down...")
            for window in windows {
                let urls = findSelectedFileURLs(in: window, depth: 0)
                if !urls.isEmpty { return urls }
            }
        }

        // Strategy C: Focused window
        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef) == .success {
            print("🔍 AX: Searching focused window...")
            let urls = findSelectedFileURLs(in: windowRef as! AXUIElement, depth: 0)
            if !urls.isEmpty { return urls }
        }

        print("📭 AX: No selected files found")
        return nil
    }

    private func findSelectedURLsWalkingUp(from element: AXUIElement) -> [URL]? {
        var current = element
        for depth in 0 ..< 20 {
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(current, kAXRoleAttribute as CFString, &roleRef)
            let role = roleRef as? String ?? "?"

            // Check selected rows (list view, column view)
            var selectedRowsRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(current, kAXSelectedRowsAttribute as CFString, &selectedRowsRef) == .success,
               let rows = selectedRowsRef as? [AXUIElement], !rows.isEmpty {
                print("🔍 AX walk-up[\(depth)]: \(rows.count) selected row(s) in \(role)")
                let urls = rows.compactMap { extractURL(from: $0) }
                if !urls.isEmpty { return urls }
            }

            // Check selected children (icon view, Desktop)
            var selectedChildrenRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(current, kAXSelectedChildrenAttribute as CFString, &selectedChildrenRef) == .success,
               let children = selectedChildrenRef as? [AXUIElement], !children.isEmpty {
                print("🔍 AX walk-up[\(depth)]: \(children.count) selected children in \(role)")
                let urls = children.compactMap { extractURL(from: $0) }
                if !urls.isEmpty { return urls }
            }

            // Move to parent
            var parentRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(current, kAXParentAttribute as CFString, &parentRef) == .success else { break }
            current = parentRef as! AXUIElement
        }
        return nil
    }

    private func findSelectedFileURLs(in element: AXUIElement, depth: Int) -> [URL] {
        guard depth < 10 else { return [] }

        // Check selected rows
        var selectedRowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXSelectedRowsAttribute as CFString, &selectedRowsRef) == .success,
           let rows = selectedRowsRef as? [AXUIElement], !rows.isEmpty {
            let urls = rows.compactMap { extractURL(from: $0) }
            if !urls.isEmpty { return urls }
        }

        // Check selected children
        var selectedChildrenRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXSelectedChildrenAttribute as CFString, &selectedChildrenRef) == .success,
           let children = selectedChildrenRef as? [AXUIElement], !children.isEmpty {
            let urls = children.compactMap { extractURL(from: $0) }
            if !urls.isEmpty { return urls }
        }

        // Recurse into children
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return [] }

        for child in children {
            let urls = findSelectedFileURLs(in: child, depth: depth + 1)
            if !urls.isEmpty { return urls }
        }

        return []
    }

    private func extractURL(from element: AXUIElement) -> URL? {
        // Try AXURL attribute (Finder rows expose this)
        var urlRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, "AXURL" as CFString, &urlRef) == .success {
            if CFGetTypeID(urlRef!) == CFURLGetTypeID() {
                return (urlRef as! CFURL) as URL
            }
            if let urlString = urlRef as? String, let url = URL(string: urlString) {
                return url
            }
        }

        // Check children for URL (some Finder views nest it)
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return nil }

        for child in children {
            var childURLRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(child, "AXURL" as CFString, &childURLRef) == .success {
                if CFGetTypeID(childURLRef!) == CFURLGetTypeID() {
                    return (childURLRef as! CFURL) as URL
                }
                if let urlString = childURLRef as? String, let url = URL(string: urlString) {
                    return url
                }
            }
        }

        return nil
    }

    // MARK: - AppleScript Fallback

    private func getFinderSelectionViaAppleScript() -> [URL]? {
        print("🔍 Trying AppleScript...")

        // Use application ID for more reliable targeting
        let script = """
        try
            tell application id "com.apple.finder"
                set selectedItems to selection
                if (count of selectedItems) is 0 then
                    return ""
                end if
                set pathList to ""
                repeat with anItem in selectedItems
                    if pathList is not "" then
                        set pathList to pathList & "||"
                    end if
                    try
                        set pathList to pathList & POSIX path of (anItem as alias)
                    end try
                end repeat
                return pathList
            end tell
        on error errMsg number errNum
            return "ERROR:" & errNum
        end try
        """

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            print("🚨 Failed to create AppleScript object")
            return nil
        }

        let output = appleScript.executeAndReturnError(&error)

        guard error == nil else {
            let errorNum = error?["NSAppleScriptErrorNumber"] as? Int ?? 0
            let errorMsg = error?["NSAppleScriptErrorBriefMessage"] as? String ?? "unknown"
            print("🚨 AppleScript error (\(errorNum)): \(errorMsg)")

            // Try clipboard fallback for Finder
            print("🔄 Trying clipboard fallback for Finder...")
            return getFinderSelectionViaClipboard()
        }

        let pathString = output.stringValue ?? ""

        // Check if script returned an error
        if pathString.hasPrefix("ERROR:") {
            print("🚨 AppleScript internal error: \(pathString)")
            return getFinderSelectionViaClipboard()
        }

        if pathString.isEmpty {
            print("📭 AppleScript returned empty result (no selection)")
            return []
        }

        let paths = pathString.components(separatedBy: "||")
        let urls = paths.map { URL(fileURLWithPath: $0) }
        print("✅ AppleScript found \(urls.count) file(s)")
        return urls
    }

    // MARK: - Clipboard Fallback for Finder

    private func getFinderSelectionViaClipboard() -> [URL]? {
        print("🔍 Trying clipboard method for Finder...")

        let pasteboard = NSPasteboard.general
        let oldContent = pasteboard.pasteboardItems

        // Clear and trigger Cmd+C
        pasteboard.clearContents()

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        // Wait for clipboard to update
        Thread.sleep(forTimeInterval: 0.15)

        // Try to read file URLs from clipboard
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]

        // Restore old clipboard content
        pasteboard.clearContents()
        if let oldContent = oldContent {
            pasteboard.writeObjects(oldContent)
        }

        if let urls = urls, !urls.isEmpty {
            print("✅ Clipboard method found \(urls.count) file(s)")
            return urls
        }

        print("📭 Clipboard method found no files")
        return nil
    }

    // MARK: - File Reading

    private func readFileContent(at url: URL) -> String? {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path) else { return nil }

        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }

        let maxSize: Int64 = 10 * 1024 * 1024
        guard fileSize <= maxSize else {
            return "[File too large: \(formatFileSize(fileSize)). Maximum supported size is 10MB]"
        }

        let textExtensions: Set<String> = [
            "txt", "md", "markdown", "text",
            "swift", "py", "js", "ts", "jsx", "tsx",
            "java", "c", "cpp", "h", "hpp",
            "json", "xml", "yaml", "yml", "toml",
            "html", "css", "scss", "sass",
            "sh", "bash", "zsh",
            "rs", "go", "rb", "php",
            "sql", "log", "csv",
            "rtf", "tex"
        ]

        let ext = url.pathExtension.lowercased()
        guard textExtensions.contains(ext) || ext.isEmpty else {
            return nil
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            return nil
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
