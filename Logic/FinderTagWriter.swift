import Darwin
import Foundation

/// Writes Finder tags back to files by editing the raw
/// `com.apple.metadata:_kMDItemUserTags` extended attribute.
///
/// The raw `"Name\n<colorIndex>"` entries are edited directly instead of going
/// through `NSURL.setResourceValue(_:forKey: .tagNamesKey)` because the official
/// API destroys color information: a read-modify-write round trip of tag *names*
/// rewrites every entry with color 0 (verified empirically 2026-07-07 -- a
/// `"SpikeColor\n6"` entry came back as `"SpikeColor\n0"`).
enum FinderTagWriter {
    private static let attributeName = "com.apple.metadata:_kMDItemUserTags"

    enum WriteError: LocalizedError {
        case xattrFailed(path: String, errno: Int32)

        var errorDescription: String? {
            switch self {
            case .xattrFailed(let path, let code):
                return "\(path): \(String(cString: strerror(code)))"
            }
        }
    }

    // MARK: - Pure entry editing (unit tested, no I/O)

    /// Returns the entries with `name` added. Existing entries -- including their
    /// color suffixes -- are preserved untouched; if the tag is already present
    /// (under either the `"Name"` or `"Name\nX"` form) the input is returned as is.
    /// The new entry is written as `"Name\n<colorIndex>"` with 0 meaning no color,
    /// matching what Finder itself writes.
    static func addingTag(_ name: String, colorIndex: Int?, to rawEntries: [String]) -> [String] {
        guard !rawEntries.contains(where: { FinderTagColor.parseNameAndColorIndex($0).name == name }) else {
            return rawEntries
        }
        return rawEntries + ["\(name)\n\(colorIndex ?? 0)"]
    }

    /// Returns the entries with every entry named `name` removed (matches both the
    /// bare `"Name"` and the `"Name\nX"` forms). Other entries are preserved.
    static func removingTag(_ name: String, from rawEntries: [String]) -> [String] {
        rawEntries.filter { FinderTagColor.parseNameAndColorIndex($0).name != name }
    }

    // MARK: - I/O

    /// Writes the raw entries as a binary plist xattr; an empty array removes the
    /// attribute entirely, matching Finder's behavior when the last tag is removed.
    static func writeRawEntries(_ entries: [String], to url: URL) throws {
        let path = url.path

        if entries.isEmpty {
            let result = removexattr(path, attributeName, 0)
            // ENOATTR (attribute already absent) is success for our purposes.
            guard result == 0 || errno == ENOATTR else {
                throw WriteError.xattrFailed(path: path, errno: errno)
            }
            return
        }

        let data = try PropertyListSerialization.data(fromPropertyList: entries, format: .binary, options: 0)
        let result = data.withUnsafeBytes { bytes in
            setxattr(path, attributeName, bytes.baseAddress, data.count, 0, 0)
        }
        guard result == 0 else {
            throw WriteError.xattrFailed(path: path, errno: errno)
        }
    }
}
