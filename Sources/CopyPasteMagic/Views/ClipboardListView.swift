import SwiftUI

struct ClipboardListView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var panelState: PanelState
    let onSelect: (ClipboardEntry) -> Void

    @State private var searchText = ""

    private var filteredEntries: [ClipboardEntry] {
        if searchText.isEmpty {
            return clipboardManager.entries
        }
        return clipboardManager.entries.filter {
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Rechercher...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.bar)

            Divider()

            // Clipboard entries list
            if filteredEntries.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text(searchText.isEmpty ? "Historique vide" : "Aucun résultat")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { index, entry in
                                ClipboardRowView(entry: entry, isSelected: index == panelState.selectedIndex)
                                    .id(entry.id)
                                    .padding(.horizontal, 10)
                                    .onTapGesture {
                                        onSelect(entry)
                                    }
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }

                                if entry.id != filteredEntries.last?.id {
                                    Divider()
                                        .padding(.horizontal, 10)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: panelState.selectedIndex) { _, newIndex in
                        // Scroll to keep selected entry visible
                        if newIndex < filteredEntries.count {
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(filteredEntries[newIndex].id, anchor: nil)
                            }
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Text("\(clipboardManager.entries.count) élément(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Vider") {
                    clipboardManager.clearHistory()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.red)
            }
            .padding(8)
        }
        .frame(minWidth: 380, minHeight: 400)
        .onChange(of: filteredEntries.count) { _, newCount in
            panelState.entryCount = newCount
            if panelState.selectedIndex >= newCount {
                panelState.selectedIndex = max(0, newCount - 1)
            }
        }
        .onChange(of: panelState.confirmSelection) { _, confirm in
            if confirm {
                panelState.confirmSelection = false
                let entries = filteredEntries
                if panelState.selectedIndex < entries.count {
                    onSelect(entries[panelState.selectedIndex])
                }
            }
        }
        .onAppear {
            panelState.entryCount = filteredEntries.count
        }
    }
}
