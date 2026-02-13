import SwiftUI

struct MenuBarView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    let onShowHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                onShowHistory()
            } label: {
                Label("Afficher l'historique", systemImage: "list.clipboard")
            }
            .keyboardShortcut("v", modifiers: .option)

            Divider()

            if !clipboardManager.entries.isEmpty {
                // Show last 5 entries as quick access
                ForEach(clipboardManager.entries.prefix(5)) { entry in
                    Button {
                        clipboardManager.copyToClipboard(entry)
                    } label: {
                        Text(entry.type == .image ? "🖼️ \(entry.preview)" : entry.preview)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Divider()
            }

            Button(role: .destructive) {
                clipboardManager.clearHistory()
            } label: {
                Label("Vider l'historique", systemImage: "trash")
            }

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quitter", systemImage: "power")
            }
            .keyboardShortcut("q")
        }
        .frame(width: 260)
    }
}
