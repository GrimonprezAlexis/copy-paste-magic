import Foundation

enum ClipboardEntryType: String, Codable {
    case text
    case url
    case image
}

struct ClipboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let type: ClipboardEntryType
    let timestamp: Date
    let preview: String
    let imageFileName: String?

    init(content: String, type: ClipboardEntryType, imageFileName: String? = nil) {
        self.id = UUID()
        self.content = content
        self.type = type
        self.timestamp = Date()
        self.preview = String(content.prefix(200))
        self.imageFileName = imageFileName
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var typeIcon: String {
        switch type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"
        }
    }

    var imageURL: URL? {
        guard type == .image, let imageFileName else { return nil }
        return Storage.imagesURL.appendingPathComponent(imageFileName)
    }
}
