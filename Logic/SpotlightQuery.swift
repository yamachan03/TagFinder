import CoreServices
import Foundation

/// Thin wrapper around the CoreServices MDQuery C API -- the same engine `mdfind`
/// uses. NSMetadataQuery is deliberately NOT used: on this machine (macOS 26.5)
/// it returns zero results for every predicate and scope even with Full Disk
/// Access granted, while raw MDQuery queries against the identical query string
/// and home scope return correct results (verified empirically 2026-07-06).
enum SpotlightQuery {
    struct Item: Sendable {
        let path: String
        let tags: [String]
    }

    /// Runs `queryString` (mdfind syntax) synchronously across all local mounted
    /// volumes -- the startup disk, the user's home, and external drives -- matching
    /// what Finder's tag sidebar covers. Blocking -- call from a background task,
    /// not the main thread. Returns nil if the query string fails to parse or the
    /// query cannot execute.
    static func runOnAllLocalVolumes(_ queryString: String) -> [Item]? {
        guard let query = MDQueryCreate(kCFAllocatorDefault, queryString as CFString, nil, nil) else {
            return nil
        }
        MDQuerySetSearchScope(query, [kMDQueryScopeComputer] as CFArray, 0)
        guard MDQueryExecute(query, CFOptionFlags(kMDQuerySynchronous.rawValue)) else {
            return nil
        }

        var items: [Item] = []
        for index in 0..<MDQueryGetResultCount(query) {
            guard let rawItem = MDQueryGetResultAtIndex(query, index) else { continue }
            let item = Unmanaged<MDItem>.fromOpaque(rawItem).takeUnretainedValue()
            guard let path = MDItemCopyAttribute(item, kMDItemPath) as? String else { continue }
            let tags = MDItemCopyAttribute(item, "kMDItemUserTags" as CFString) as? [String] ?? []
            items.append(Item(path: path, tags: tags))
        }
        return items
    }

    /// Escapes a value for embedding inside single quotes in an MDQuery query
    /// string: backslash and single quote are the two characters with special
    /// meaning there. Tag names may contain quotes, backslashes, or arbitrary
    /// Unicode, so never interpolate them unescaped.
    static func escapeValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }
}
