import ApplicationServices
import SwiftUI

@main
struct CopyPasteMagicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                clipboardManager: appDelegate.clipboardManager,
                onShowHistory: { appDelegate.panelManager.toggle() }
            )
        } label: {
            Image(systemName: "clipboard")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let clipboardManager = ClipboardManager()
    let hotkeyManager = HotkeyManager()
    lazy var panelManager = PanelManager(clipboardManager: clipboardManager)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Prompt for Accessibility permission if not granted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Register global hotkey ⌥V
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.panelManager.toggle()
        }
        hotkeyManager.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
        clipboardManager.stopMonitoring()
    }
}
