import AppKit
import SwiftUI

// Shared state between PanelManager (keyboard handler) and SwiftUI views
final class PanelState: ObservableObject {
    @Published var selectedIndex: Int = 0
    @Published var confirmSelection: Bool = false

    var entryCount: Int = 0

    func moveUp() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }

    func moveDown() {
        if selectedIndex < entryCount - 1 { selectedIndex += 1 }
    }

    func reset() {
        selectedIndex = 0
        confirmSelection = false
    }
}

// NSPanel subclass that can become key without activating the app
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class PanelManager {
    private var panel: FloatingPanel?
    private var keyMonitor: Any?
    private let clipboardManager: ClipboardManager
    private let panelState = PanelState()
    private var previousApp: NSRunningApplication?

    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        // Remember the frontmost app so we can restore it after selection
        previousApp = NSWorkspace.shared.frontmostApplication

        if panel == nil {
            createPanel()
        }

        guard let panel, let screen = NSScreen.main else { return }

        panelState.reset()

        let panelWidth: CGFloat = 420
        let panelHeight: CGFloat = 500
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panelWidth / 2
        let y = screenFrame.midY - panelHeight / 2

        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        panel.makeKeyAndOrderFront(nil)

        // Activate so keyboard input works in the panel (search field + arrow keys)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func selectEntry(_ entry: ClipboardEntry) {
        clipboardManager.copyToClipboard(entry)
        hide()
        NSApp.hide(nil)
        previousApp?.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            Self.simulatePaste()
        }
    }

    private static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func createPanel() {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isFloatingPanel = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow
        panel.backgroundColor = .windowBackgroundColor

        let listView = ClipboardListView(
            clipboardManager: clipboardManager,
            panelState: panelState,
            onSelect: { [weak self] entry in
                self?.selectEntry(entry)
            }
        )
        panel.contentView = NSHostingView(rootView: listView)

        // Intercept arrow keys, Enter, Escape at the panel level
        // so they work regardless of which SwiftUI element has focus
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible else { return event }

            switch event.keyCode {
            case 125: // Down arrow
                self.panelState.moveDown()
                return nil
            case 126: // Up arrow
                self.panelState.moveUp()
                return nil
            case 36: // Return/Enter
                self.panelState.confirmSelection = true
                return nil
            case 53: // Escape
                self.hide()
                return nil
            default:
                return event // Pass through to search field
            }
        }

        self.panel = panel
    }
}
