import AppKit

struct FoundFile: Identifiable, Hashable {
    let url: URL
    let tags: [String]

    var id: URL { url }

    var displayName: String { url.lastPathComponent }

    var containingFolder: String {
        url.deletingLastPathComponent().path
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    var isDirectory: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }
}
