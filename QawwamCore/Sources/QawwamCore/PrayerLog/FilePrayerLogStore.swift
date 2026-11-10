import Foundation

/// Loads and saves the whole prayer log.
public protocol PrayerLogStore: Sendable {
    /// The saved log, or an empty log if nothing is saved yet.
    func load() throws -> PrayerLog
    func save(_ log: PrayerLog) throws
}

/// Keeps the log in one JSON file. In the app the file sits in the App Group folder so widgets can read it.
public struct FilePrayerLogStore: PrayerLogStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// A missing file is an empty log. A file that can't be read throws, so history is never silently wiped.
    public func load() throws -> PrayerLog {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return PrayerLog()
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(PrayerLog.self, from: data)
    }

    /// Writes to a temporary file and swaps it in, so a crash mid-save can't leave half a file.
    public func save(_ log: PrayerLog) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(log).write(to: fileURL, options: .atomic)
    }
}
