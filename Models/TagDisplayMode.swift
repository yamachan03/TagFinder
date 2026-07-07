import Foundation

/// How the sidebar presents discovered tags.
enum TagDisplayMode: String, CaseIterable, Identifiable {
    /// One tag per row with its file count (default).
    case listWithCount
    /// Compact chips without counts, wrapping to as many columns as fit.
    case chipFlow

    var id: String { rawValue }

    /// LanguageManager lookup key for the settings label.
    var labelKey: String {
        switch self {
        case .listWithCount: return "List with file counts"
        case .chipFlow: return "Tags only (wrap)"
        }
    }
}
