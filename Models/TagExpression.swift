import Foundation

/// Boolean expression over tag names, e.g. `(A and B) or (C and D) or E`.
/// The canonical search model: the simple mode (flat AND/OR of selected tags)
/// and the advanced group builder both compile down to this. Codable so
/// expressions can be persisted later (saved searches).
indirect enum TagExpression: Equatable, Codable {
    case tag(String)
    case and([TagExpression])
    case or([TagExpression])

    /// mdfind-syntax query string for MDQuery, or nil if the expression contains
    /// no tags at all (empty compounds are skipped recursively, so groups the
    /// user hasn't filled in yet simply drop out of the search).
    var queryString: String? {
        render(.query)?.text
    }

    /// Human-readable form for the results header, e.g. `(A AND B) OR E`.
    var displayString: String? {
        render(.display)?.text
    }

    private enum Style {
        case query
        case display

        var andJoiner: String { self == .query ? " && " : " AND " }
        var orJoiner: String { self == .query ? " || " : " OR " }

        func leaf(_ name: String) -> String {
            switch self {
            case .query: return "kMDItemUserTags == '\(SpotlightQuery.escapeValue(name))'"
            case .display: return name
            }
        }
    }

    private func render(_ style: Style) -> (text: String, isCompound: Bool)? {
        switch self {
        case .tag(let name):
            return (style.leaf(name), false)
        case .and(let children):
            return Self.renderCompound(children, joiner: style.andJoiner, style: style)
        case .or(let children):
            return Self.renderCompound(children, joiner: style.orJoiner, style: style)
        }
    }

    private static func renderCompound(
        _ children: [TagExpression],
        joiner: String,
        style: Style
    ) -> (text: String, isCompound: Bool)? {
        let rendered = children.compactMap { $0.render(style) }
        guard let first = rendered.first else { return nil }
        // A compound that collapses to one effective child IS that child --
        // no parentheses of its own (the parent decides whether to wrap it).
        guard rendered.count > 1 else { return first }
        let parts = rendered.map { $0.isCompound ? "(\($0.text))" : $0.text }
        return (parts.joined(separator: joiner), true)
    }
}
