# BarKeep

<p align="center">
  <strong>A lightweight, lightning-fast macOS menu bar manager built from scratch with Swift and SwiftUI.</strong>
</p>

<p align="center">
  <a href="README.md"><strong>English</strong></a> •
  <a href="docs/README.ru.md">Русский</a> •
  <a href="docs/README.kk.md">Қазақша</a> •
  <a href="docs/README.zh.md">简体中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014.0%2B-blue?style=flat-square" alt="Platform: macOS 14.0+" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange?style=flat-square" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/architecture-Apple%20Silicon%20%7C%20Intel-green?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/license-MIT-purple?style=flat-square" alt="License" />
</p>

---

## Overview

**BarKeep** is an open-source macOS menu bar manager inspired by Bartender and Ice. It hides excess menu bar icons off-screen, gives you instant access to hidden items via a floating panel, supports instant fuzzy search across multiple languages, expands automatically on mouse hover, and restores every icon with a single safety hotkey.

Built natively in **Swift, AppKit, and SwiftUI** with zero third-party dependencies. No GPL code was copied; all mechanics were designed and implemented from the ground up.

---

## Features

- **Off-Screen Icon Hiding**: Expands a zero-profile status item divider to 10,000 px, gracefully pushing all items to its left beyond the screen edge.
- **Floating Bar Panel** (*Left Click* on the BarKeep icon): A sleek HUD window displaying real-time snapshots of hidden items with horizontal trackpad/wheel scrolling.
- **Multilingual Search**: Instant search with built-in transliteration support (e.g. typing in Cyrillic/Kazakh/Latin finds matching apps regardless of layout). Press `Enter` to activate the top match; `Esc` or click outside to dismiss.
- **Native Click Activation**: Clicking a hidden item in the panel temporarily reveals its menu bar section, triggers an `AXPress` accessibility event to open its native menu, and automatically hides the section when finished.
- **Hover to Reveal**: Hover the mouse cursor over the empty menu bar space to slide hidden icons into view; move the cursor away to collapse them back.
- **Process Management Context Menu**: Right-click any icon in the panel to activate, hide, terminate, or force-quit the host application (with safety confirmation dialogs for non-system apps).
- **Global Hotkeys**: Global hotkeys powered by Carbon's `RegisterEventHotKey`:
  - `⌃⌥⌘H` — Toggle Hidden section
  - `⌃⌥⌘A` — Toggle Always Hidden section
  - `⌃⌥⌘R` — Emergency safety reset (brings all icons back)
- **Multi-Language Support**:
  - English (Default)
  - Russian (Русский)
  - Kazakh (Қазақша)
  - Simplified Chinese (简体中文)
  - Switch languages on the fly from the status item menu without restarting.
- **Graceful Termination & Recovery**: All dividers are cleanly reset upon quit, ensuring your menu bar never remains in an inconsistent or hidden state.
- **Developer & Scripting Friendly**: Full CLI toolset for scanning and toggling via command-line arguments.
- **Reproducible Local Codesigning**: Dedicated build scripts generate a persistent local keychain certificate so macOS TCC permissions (Accessibility & Screen Recording) survive repeated debug builds.

---

## Requirements

- **macOS 14.0 (Sonoma)** or later (tested on macOS 15 Sequoia, Apple Silicon and Intel).
- **Xcode 15.0+** and Command Line Tools.
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** (`brew install xcodegen`).
- No paid Apple Developer account needed: uses a local self-signed certificate.

---

## Quick Start & Build

Clone the repository and build the debug app:

```bash
git clone https://github.com/your-username/BarKeep.git
cd BarKeep

# 1. Generate local development signing certificate (first time only)
make signing

# 2. Generate Xcode project files and compile
make gen
make build

# 3. Launch BarKeep
make run
```

### Useful Makefile Commands

| Command | Description |
|---|---|
| `make signing` | Sets up a persistent local keychain certificate (`BarKeep Dev`) |
| `make gen` | Generates `BarKeep.xcodeproj` from `project.yml` |
| `make build` | Compiles and codesigns the debug build in `build/` |
| `make run` | Kills any existing instance and launches the fresh app |
| `make stop` | Gracefully terminates BarKeep (restores all icons) |
| `make logs` | Tails live log output (`~/Library/Logs/BarKeep.log`) |
| `make report` | Displays recent diagnostic log entries |
| `make clean` | Removes build artifacts and the generated Xcode project |

---

## Permissions Setup

When first launched, BarKeep prompts for two macOS system permissions:

1. **Accessibility**: Required to scan item positions, read AX accessibility trees, and simulate clicks on third-party menu bar items.
2. **Screen Recording**: Required to capture crisp image snapshots of hidden icons for display in the floating HUD panel.

To grant them:
1. Open **System Settings → Privacy & Security**.
2. Navigate to **Accessibility** and turn the toggle **ON** for `BarKeep`.
3. Navigate to **Screen Recording** and turn the toggle **ON** for `BarKeep`.
4. Relaunch BarKeep.

> **Note**: If you run BarKeep directly inside a terminal process, macOS attributes permissions to your terminal emulator (e.g. Terminal, iTerm2, Kitty). For isolated production testing, launch using `open build/Build/Products/Debug/BarKeep.app`.

---

## User Controls & Shortcuts

| Action | Control |
|---|---|
| **Toggle Floating Panel** | Left Click on BarKeep icon |
| **Open Settings & Menu** | Right Click or `⌃` + Left Click on BarKeep icon |
| **Toggle Hidden Section** | `⌃⌥⌘H` |
| **Toggle Always Hidden** | `⌃⌥⌘A` |
| **Emergency Safety Reset** | `⌃⌥⌘R` |

### Changing Menu Bar Sections

BarKeep's layout divides the menu bar into three distinct zones:
`[System Items] [BarKeep] [Visible Items] | Hidden Divider | [Hidden Items] | Always Hidden Divider | [Always Hidden]`

1. Reveal hidden icons using `⌃⌥⌘H` or open the floating panel.
2. Hold the `⌘` key and drag the thin vertical separator bar in the menu bar to adjust the boundary between visible and hidden icons.
3. Alternatively, hold `⌘` and drag any third-party icon across the divider to assign it to the desired section.
4. Press `⌃⌥⌘H` again to collapse the section.

---

## Language Settings

BarKeep supports 4 languages with English set as the default:

1. Right-click the BarKeep menu bar icon to open the context menu.
2. Hover over **Language**.
3. Select your preferred language:
   - **English** (Default)
   - **Русский**
   - **Қазақша**
   - **简体中文**

The UI, menu items, search transliteration, floating panel, and confirmation dialogs update immediately without needing a restart. Your preference is automatically persisted across application launches.

---

## CLI & Automation

The compiled binary includes built-in CLI commands useful for scripting, terminal integration, and automation:

```bash
# Scan and list all active menu bar items (coordinates, AX, PID, Bundle ID)
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --scan

# Activate a specific item by title or window ID
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --press "Control Center"

# Control running instance through the internal command bus
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send showHidden
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send hideHidden
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send toggleHidden
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send reset
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send panel
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send "activate:Telegram"
./build/Build/Products/Debug/BarKeep.app/Contents/MacOS/BarKeep --send quit
```

---

## Architecture & Code Structure

```
BarKeep/
├── App/
│   ├── AppDelegate.swift          # Lifecycle, permission alerts, hotkeys, commands
│   ├── AppEnvironment.swift       # Screen geometry, conflicting manager detection
│   ├── BarKeepApp.swift           # CLI entry point and application launcher
│   └── Info.plist                 # Bundle metadata and LSUIElement accessory policy
├── Core/
│   ├── AX/                        # Accessibility wrappers and AXUIElement helpers
│   ├── Capture/                   # ScreenCaptureKit/CGWindowList icon snapshot cache
│   ├── CommandBus.swift           # Inter-process and CLI distributed notification bus
│   ├── Hotkeys/                   # Carbon HIToolbox global hotkey registration
│   ├── Localization/              # AppLanguage enum, translations (en, ru, kk, zh)
│   ├── Logging/                   # File & console logging (~/Library/Logs/BarKeep.log)
│   ├── MenuBar/                   # Item scanning, layout calculations, hover reveal
│   └── Permissions/               # Accessibility and Screen Recording TCC management
├── UI/
│   ├── BarPanel/                  # SwiftUI floating HUD bar, icon scroller, fuzzy search
│   ├── ClosureMenuItem.swift      # Clean closure-based NSMenuItem subclass
│   └── StatusItemController.swift # Status bar icon menu, settings, language picker
├── Makefile                       # Developer build & lifecycle workflow
├── project.yml                    # Declarative XcodeGen configuration
└── scripts/
    └── setup-signing.sh           # Local development keychain certificate generator
```

---

## Diagnostics & Troubleshooting

- **Live Logs**: `~/Library/Logs/BarKeep.log` or run `make logs`.
- **Diagnostic Snapshot**: Right-click BarKeep icon → click **Copy Report to Clipboard**.
- **Emergency Recovery**: Press `⌃⌥⌘R` or run `BarKeep --send reset` to instantly restore all icons to their normal positions.
- **Conflicts**: Running BarKeep simultaneously with Ice or Bartender can cause status item separator jitter. BarKeep automatically detects conflicting managers and displays a warning in the menu.

---

## Contributing

Contributions are welcome! Please feel free to submit issues, feature suggestions, or pull requests:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## License

This project is licensed under the [MIT License](LICENSE).
