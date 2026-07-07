import Foundation

/// One group in the advanced-search expression builder: a flat AND/OR of tag
/// names. Groups are combined by AppState.outerMode into the full expression --
/// the UI deliberately builds two levels (e.g. OR of AND-groups), which covers
/// forms like `(A and B) or (C and D) or E`; TagExpression itself supports
/// arbitrary nesting.
struct ExpressionGroup: Identifiable, Equatable {
    let id = UUID()
    var mode: MatchMode = .and
    var tags: [String] = []

    var expression: TagExpression? {
        guard !tags.isEmpty else { return nil }
        let leaves = tags.map(TagExpression.tag)
        return mode == .and ? .and(leaves) : .or(leaves)
    }
}

/// Which search UI is active in the sidebar.
enum SearchMode: String, CaseIterable, Identifiable {
    case simple
    case advanced

    var id: String { rawValue }

    /// LanguageManager lookup key.
    var labelKey: String {
        switch self {
        case .simple: return "Simple"
        case .advanced: return "Advanced"
        }
    }
}
