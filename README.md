# Verbe

[[insert logo here]]

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Verbe is a macOS assistant prototype focused on fast, contextual interactions through voice, overlay UI, and on-screen understanding.

This project was built for the [Gemini 3 Hackathon](https://gemini3.devpost.com/) and is archived here as a hackathon submission. It will not be actively edited in this repository.

## Project Organization

```text
Verbe/
├─ Verbe/                    # Main macOS app (Swift/SwiftUI)
│  ├─ App/                   # App lifecycle and dependency wiring
│  ├─ Runtime/               # Overlay, voice, vision, and runtime services
│  ├─ Shared/                # Reusable UI components, styles, and services
│  ├─ SettingsApp/           # Settings UI and view models
│  └─ Resources/             # Assets, entitlements, and app resources
├─ Documentation/            # Product notes, architecture drafts, definitions
├─ website/                  # Marketing/demo web pages and mock assets
└─ gemini-voice-drafter/     # Companion voice drafting prototype (web)
```

## License

Released under the MIT License. See [LICENSE](./LICENSE).
