import Foundation

/// A persisted search condition. Captures the full builder state (simple or
/// advanced) rather than just the compiled expression, so recalling a saved
/// search restores an editable UI. Stored as JSON in UserDefaults.
struct SavedSearch: Identifiable, Equatable, Codable {
    /// One builder group, stored without the runtime UUID -- fresh ids are
    /// minted when the search is recalled.
    struct Group: Equatable, Codable {
        var mode: MatchMode
        var terms: [GroupTerm]
    }

    var id = UUID()
    var name: String
    var mode: SearchMode

    // Simple-mode state
    var matchMode: MatchMode
    var selectedTags: [String]

    // Advanced-mode state
    var outerMode: MatchMode
    var groups: [Group]

    /// Rebuilds runtime builder groups (with fresh UUIDs) for the UI.
    var expressionGroups: [ExpressionGroup] {
        groups.map { ExpressionGroup(mode: $0.mode, terms: $0.terms) }
    }

    /// The expression this saved search represents, for previews/tooltips.
    var expression: TagExpression? {
        switch mode {
        case .simple:
            guard !selectedTags.isEmpty else { return nil }
            let leaves = selectedTags.map(TagExpression.tag)
            return matchMode == .and ? .and(leaves) : .or(leaves)
        case .advanced:
            let parts = expressionGroups.compactMap(\.expression)
            guard !parts.isEmpty else { return nil }
            return outerMode == .and ? .and(parts) : .or(parts)
        }
    }
}
