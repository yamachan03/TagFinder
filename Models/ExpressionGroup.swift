import Foundation

/// One tag term inside a group; `negated` turns it into a NOT (exclusion).
struct GroupTerm: Identifiable, Equatable {
    var name: String
    var negated = false

    var id: String { name }

    var expression: TagExpression {
        negated ? .not(.tag(name)) : .tag(name)
    }
}

/// One group in the advanced-search expression builder: a flat AND/OR of
/// (possibly negated) tag terms. Groups are combined by AppState.outerMode into
/// the full expression -- the UI deliberately builds two levels (e.g. OR of
/// AND-groups), which covers forms like `(A and not B) or (C and D) or E`;
/// TagExpression itself supports arbitrary nesting.
struct ExpressionGroup: Identifiable, Equatable {
    let id = UUID()
    var mode: MatchMode = .and
    var terms: [GroupTerm] = []

    var expression: TagExpression? {
        guard !terms.isEmpty else { return nil }
        let leaves = terms.map(\.expression)
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
