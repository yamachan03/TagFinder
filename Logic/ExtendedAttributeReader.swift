import Darwin
import Foundation

/// Reads the raw `com.apple.metadata:_kMDItemUserTags` extended attribute that Finder
/// writes on tagged files. This is the only way to recover a tag's color index, since
/// Spotlight's `kMDItemUserTags` metadata attribute exposes tag names only.
enum ExtendedAttributeReader {
    private static let attributeName = "com.apple.metadata:_kMDItemUserTags"

    /// Returns the decoded array of `"Name\n<colorIndex>"` strings, or `nil` if the
    /// attribute is absent, unreadable, or not a plist array of strings.
    static func rawUserTagsPropertyList(at url: URL) -> [String]? {
        let path = url.path

        let neededSize = getxattr(path, attributeName, nil, 0, 0, 0)
        guard neededSize > 0 else { return nil }

        var buffer = [UInt8](repeating: 0, count: neededSize)
        let readSize = getxattr(path, attributeName, &buffer, neededSize, 0, 0)
        guard readSize > 0 else { return nil }

        let data = Data(buffer[0..<readSize])
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) else {
            return nil
        }
        return plist as? [String]
    }
}
