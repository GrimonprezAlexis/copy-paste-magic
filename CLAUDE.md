# CLAUDE.md

## Project Overview
Copy Paste Magic is a native macOS clipboard history manager built with Swift and SwiftUI. It runs as a menu bar app, monitors the system clipboard, and displays a floating popup with history when the user presses ⌥V (Option+V).

## Tech Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI + AppKit (NSPanel)
- **Build**: Swift Package Manager
- **Target**: macOS 14+
- **Hotkey**: Carbon `RegisterEventHotKey` API
- **Paste simulation**: CGEvent

## Project Structure
```
Sources/CopyPasteMagic/
├── App.swift              # @main entry point, AppDelegate, MenuBarExtra
├── ClipboardEntry.swift   # Codable data model (text, image, URL)
├── ClipboardManager.swift # NSPasteboard polling + entry storage
├── HotkeyManager.swift    # Global ⌥V hotkey via Carbon API
├── PanelManager.swift     # Floating NSPanel + keyboard nav + auto-paste
├── Storage.swift          # JSON persistence + image file management
└── Views/
    ├── ClipboardListView.swift  # Search + scrollable entry list
    ├── ClipboardRowView.swift   # Row with icon/thumbnail + preview
    └── MenuBarView.swift        # Status bar dropdown menu
```

## Build & Run
```bash
./build.sh   # Builds, signs, and launches the .app bundle
```

## Key Architecture Decisions
- **Carbon hotkey** instead of NSEvent monitors: Carbon `RegisterEventHotKey` intercepts ⌥V at the system level before macOS processes it as √
- **CGEvent paste simulation**: After selecting an entry, the app copies to clipboard, restores the previous app, and simulates ⌘V via CGEvent
- **NSPanel with `.nonactivatingPanel`**: Floating panel that can receive keyboard input without stealing focus permanently
- **Image storage**: Images saved as PNG files in `~/Library/Application Support/CopyPasteMagic/images/`, referenced by filename in the JSON history
- **Ad-hoc code signing**: Required for Accessibility permission (CGEvent posting). A dev certificate is preferred to avoid re-granting after each rebuild

## Permissions
The app requires **Accessibility** permission (System Settings → Privacy & Security → Accessibility) for:
- CGEvent posting (simulating ⌘V paste)

## Common Tasks
- **Add a new clipboard type**: Update `ClipboardEntryType` enum, add detection in `ClipboardManager.checkClipboard()`, update `ClipboardRowView` for display
- **Change hotkey**: Modify `kVK_ANSI_V` and `optionKey` in `HotkeyManager.register()`
- **Adjust max history**: Change `maxEntries` in `ClipboardManager`
