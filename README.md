# Copy Paste Magic

A native macOS clipboard history manager that lives in your menu bar.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Clipboard monitoring** — Automatically captures text, URLs, and images
- **Global hotkey ⌥V** — Opens a floating panel with your clipboard history
- **Keyboard navigation** — Arrow keys to navigate, Enter to paste, Escape to close
- **Auto-paste** — Selected entries are pasted directly into the previous app
- **Search** — Filter entries by content
- **Image support** — Thumbnails preview with 🖼️ indicator
- **Persistence** — History saved to disk, survives app restarts
- **Menu bar** — Quick access to recent entries from the status bar icon

## Installation

### Prerequisites
- macOS 14 (Sonoma) or later
- Swift 5.9+ (comes with Xcode)

### Build & Run

```bash
git clone git@github.com:GrimonprezAlexis/copy-paste-magic.git
cd copy-paste-magic
./build.sh
```

The build script will:
1. Compile the Swift package
2. Bundle it as a `.app`
3. Code sign it
4. Launch the app

### Permissions

On first launch, grant **Accessibility** permission when prompted:
**System Settings → Privacy & Security → Accessibility → CopyPasteMagic ✅**

This is required for the auto-paste feature (simulating ⌘V).

## Usage

| Action | Shortcut |
|---|---|
| Open clipboard history | `⌥V` (Option+V) |
| Navigate entries | `↑` `↓` |
| Paste selected entry | `Enter` or click |
| Close panel | `Escape` |
| Search | Just start typing |

### Menu Bar

Click the clipboard icon in the menu bar for quick access to:
- Last 5 clipboard entries
- Clear history
- Quit

## How It Works

1. The app polls `NSPasteboard` every 0.5s to detect new clipboard content
2. New entries (text, URLs, images) are stored in memory and persisted as JSON
3. Images are saved as PNG files in `~/Library/Application Support/CopyPasteMagic/images/`
4. Pressing ⌥V shows a floating `NSPanel` with the history
5. Selecting an entry copies it to clipboard, restores the previous app, and simulates ⌘V

## Data Storage

```
~/Library/Application Support/CopyPasteMagic/
├── history.json    # Clipboard entries metadata
└── images/         # Captured image files (PNG)
```

Maximum 50 entries are kept. Older entries (and their images) are automatically cleaned up.

## Development

```bash
# Build only
swift build

# Build + sign + launch
./build.sh
```

> **Note**: With ad-hoc code signing, you may need to re-grant Accessibility permission after each rebuild. Using an Apple Development certificate (via Xcode) avoids this.

## License

MIT
