import AppKit

final class Storage {
    static let appSupportURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("CopyPasteMagic", isDirectory: true)
    }()

    static let imagesURL: URL = {
        let url = appSupportURL.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private let fileURL: URL

    init() {
        try? FileManager.default.createDirectory(at: Self.appSupportURL, withIntermediateDirectories: true)
        self.fileURL = Self.appSupportURL.appendingPathComponent("history.json")
    }

    func load() -> [ClipboardEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ClipboardEntry].self, from: data)) ?? []
    }

    func save(_ entries: [ClipboardEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func saveImage(_ imageData: Data) -> String? {
        let fileName = UUID().uuidString + ".png"
        let fileURL = Self.imagesURL.appendingPathComponent(fileName)
        do {
            try imageData.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    func deleteImage(_ fileName: String) {
        let fileURL = Self.imagesURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func deleteAllImages() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: Self.imagesURL.path) else { return }
        for file in files {
            try? fm.removeItem(at: Self.imagesURL.appendingPathComponent(file))
        }
    }
}
