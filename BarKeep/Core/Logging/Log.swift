import AppKit
import Foundation

/// Простой файловый журнал: пишем в ~/Library/Logs/BarKeep.log и в stdout.
enum Log {
    static let fileURL: URL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/BarKeep.log")

    private static let queue = DispatchQueue(label: "com.reno.barkeep.log")
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func debug(_ message: String) { write("DEBUG", message) }
    static func info(_ message: String) { write("INFO", message) }
    static func warning(_ message: String) { write("WARN", message) }
    static func error(_ message: String) { write("ERROR", message) }

    private static func write(_ level: String, _ message: String) {
        let line = "[\(formatter.string(from: Date()))] \(level) \(message)\n"
        FileHandle.standardError.write(Data(line.utf8))
        queue.async {
            ensureFileExists()
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: Data(line.utf8))
            }
        }
    }

    private static func ensureFileExists() {
        guard !FileManager.default.fileExists(atPath: fileURL.path) else { return }
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
    }

    static func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
}
