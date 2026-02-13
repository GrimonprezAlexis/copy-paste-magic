import AppKit
import Combine

final class ClipboardManager: ObservableObject {
    @Published var entries: [ClipboardEntry] = []

    let storage = Storage()
    private let maxEntries = 50
    private var lastChangeCount: Int
    private var timer: Timer?

    init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        self.entries = storage.load()
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Check for image first (only if no text is present)
        let hasText = pasteboard.string(forType: .string) != nil
        let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png]
        let hasImage = imageTypes.contains(where: { pasteboard.data(forType: $0) != nil })

        if !hasText && hasImage {
            captureImage(from: pasteboard)
        } else if let string = pasteboard.string(forType: .string), !string.isEmpty {
            captureText(string)
        }
    }

    private func captureText(_ string: String) {
        // Skip if identical to the most recent entry
        if entries.first?.content == string { return }

        let type: ClipboardEntryType
        if let url = URL(string: string), url.scheme != nil, url.host != nil {
            type = .url
        } else {
            type = .text
        }

        let entry = ClipboardEntry(content: string, type: type)
        addEntry(entry)
    }

    private func captureImage(from pasteboard: NSPasteboard) {
        // Try to get image data as TIFF then convert to PNG for storage
        guard let tiffData = pasteboard.data(forType: .tiff),
              let image = NSImage(data: tiffData),
              let tiffRep = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRep),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

        // Get image dimensions for preview text
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let sizeKB = pngData.count / 1024

        guard let fileName = storage.saveImage(pngData) else { return }

        let entry = ClipboardEntry(
            content: "Image \(width)×\(height) — \(sizeKB) Ko",
            type: .image,
            imageFileName: fileName
        )
        addEntry(entry)
    }

    private func addEntry(_ entry: ClipboardEntry) {
        // Remove old entries beyond limit (and clean up their images)
        entries.insert(entry, at: 0)
        while entries.count > maxEntries {
            let removed = entries.removeLast()
            if let imageFile = removed.imageFileName {
                storage.deleteImage(imageFile)
            }
        }
        storage.save(entries)
    }

    func copyToClipboard(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if entry.type == .image, let url = entry.imageURL,
           let pngData = try? Data(contentsOf: url) {
            // Write both PNG and TIFF for maximum app compatibility
            pasteboard.declareTypes([.png, .tiff], owner: nil)
            pasteboard.setData(pngData, forType: .png)
            if let image = NSImage(data: pngData), let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        } else {
            pasteboard.setString(entry.content, forType: .string)
        }

        lastChangeCount = pasteboard.changeCount
    }

    func clearHistory() {
        // Clean up all image files
        for entry in entries {
            if let imageFile = entry.imageFileName {
                storage.deleteImage(imageFile)
            }
        }
        entries.removeAll()
        storage.save(entries)
    }

    func deleteEntry(_ entry: ClipboardEntry) {
        if let imageFile = entry.imageFileName {
            storage.deleteImage(imageFile)
        }
        entries.removeAll { $0.id == entry.id }
        storage.save(entries)
    }
}
