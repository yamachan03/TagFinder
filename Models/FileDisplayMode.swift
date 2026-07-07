import Foundation

/// How the search-result list presents each file row.
enum FileDisplayMode: String, CaseIterable, Identifiable {
    /// File name, containing folder path, and all tags on the file (default).
    case nameAndTags
    /// File name and containing folder path only.
    case nameOnly

    var id: String { rawValue }

    /// LanguageManager lookup key for the settings label.
    var labelKey: String {
        switch self {
        case .nameAndTags: return "Name, path, and tags"
        case .nameOnly: return "Name and path only"
        }
    }
}
