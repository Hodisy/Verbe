# Verbe

[![Swift](https://img.shields.io/badge/Swift-6.2%2B-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-macOS_26%2B-lightgrey)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Gemini 3 Hackathon](https://img.shields.io/badge/Gemini_3-Hackathon-4285F4?logo=google&logoColor=white)](https://devpost.com/software/verbe)

**Intelligence amplification for macOS.** Select text anywhere, pick a recipe, watch it transform.

Verbe is a native macOS utility that sits as an invisible layer on top of your system. It works in any app — Mail, Slack, VS Code, Safari, Notion, Terminal — with three gestures:

| Gesture    | Action                                           |
| ---------- | ------------------------------------------------ |
| `Cmd+Opt`  | Show radial menu, pick a recipe or type a prompt |
| `Fn`       | Voice command (hold to talk, release to send)    |
| `Fn+Shift` | Live bidirectional conversation with Gemini      |

The result appears as a floating overlay right where you're working. Insert it, copy it, or dismiss it — your workflow is never interrupted.

## Features

- **Screen as Context** — Gemini sees what you select, or your entire screen if nothing is selected. "Fix this" works when "this" is visible.
- **Recipes** — Reusable transformation templates. "Professional" rewrites text formally, "Explain Like Mom" simplifies anything. Create your own in natural language.
- **Streaming Responses** — Results stream token by token into the overlay. You start reading before the response is complete.
- **Image Generation** — Some recipes produce images instead of text, directly in the overlay.
- **Voice Command** — Hold `Fn`, speak, release. Like a walkie-talkie.
- **Voice Live** — Hold `Fn+Shift` for a real-time bidirectional conversation. Interrupt anytime.
- **Non-Intrusive Overlay** — Floats above your work, never steals focus. macOS 26 Liquid Glass design.

## Built With

- Swift + AppKit + SwiftUI
- Gemini 3 Flash Preview API (text, vision, image generation)
- Gemini 2.5 Flash Native Audio Preview API (voice live)
- macOS Accessibility API + ScreenCaptureKit
- macOS 26 Liquid Glass

## Project Structure

```text
Verbe/
├─ Verbe/
│  ├─ App/                   # App lifecycle, hotkey, permissions
│  ├─ Runtime/
│  │  ├─ Overlay/            # NSPanel overlay system
│  │  ├─ Voice/              # Voice command + Gemini Live
│  │  └─ Vision/             # Screen capture service
│  ├─ Shared/
│  │  ├─ Services/           # Gemini API client
│  │  └─ View/               # UI components (radial menu, search bar, etc.)
│  ├─ SettingsApp/           # Settings UI and recipe management
│  └─ Resources/             # Assets, entitlements
├─ Documentation/
├─ website/
└─ gemini-voice-drafter/     # Companion voice drafting prototype (web)
```

## Requirements

- macOS 26+ (Tahoe)
- Xcode 26.1.1+
- Accessibility permission (text capture + insertion)
- Input Monitoring permission (global hotkey)
- Microphone permission (voice features)

## License

> Built for the [Gemini 3 Hackathon](https://gemini3.devpost.com/). Full writeup on [Devpost](https://devpost.com/software/verbe).

Released under the MIT License. See [LICENSE](./LICENSE).

Made by **Yafa** — [@YafaHodis](https://twitter.com/YafaHodis)

![Verbe Thumbnail](./documentation/thumbnail.png)
