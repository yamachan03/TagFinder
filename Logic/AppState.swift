import Combine
import Foundation

/// Coordinates tag discovery and the filtered file search: owns the current tag
/// selection and AND/OR mode, and re-runs the file search whenever either changes.
@MainActor
final class AppState: ObservableObject {
    let tagRepository = TagRepository()
    let fileSearchController = FileSearchController()

    private var cancellables: Set<AnyCancellable> = []

    init() {
        // Nested ObservableObjects don't propagate their @Published changes through
        // the parent automatically -- forward them so views observing AppState
        // re-render when tag discovery or search results change.
        tagRepository.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        fileSearchController.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    @Published var selectedTagNames: Set<String> = [] {
        didSet { runSearch() }
    }
    @Published var matchMode: MatchMode = .and {
        didSet { runSearch() }
    }

    // MARK: - Advanced search (expression builder)

    /// Simple mode keeps the flat tag selection above; advanced mode builds a
    /// two-level expression from groups. Both compile to a TagExpression.
    @Published var searchMode: SearchMode = .simple {
        didSet {
            if searchMode == .advanced && expressionGroups.isEmpty {
                // Carry the simple selection over as the first group so the
                // transition feels continuous.
                let terms = selectedTagNames.sorted().map { GroupTerm(name: $0) }
                let seeded = ExpressionGroup(mode: matchMode, terms: terms)
                expressionGroups = [seeded]
                activeGroupID = seeded.id
            }
            runSearch()
        }
    }
    @Published var expressionGroups: [ExpressionGroup] = [] {
        didSet { if searchMode == .advanced { runSearch() } }
    }
    /// Group that sidebar tag clicks are added to while in advanced mode.
    @Published var activeGroupID: UUID?
    @Published var outerMode: MatchMode = .or {
        didSet { if searchMode == .advanced { runSearch() } }
    }

    /// The expression the current UI state represents; nil means "no search".
    var currentExpression: TagExpression? {
        switch searchMode {
        case .simple:
            guard !selectedTagNames.isEmpty else { return nil }
            let leaves = selectedTagNames.sorted().map(TagExpression.tag)
            return matchMode == .and ? .and(leaves) : .or(leaves)
        case .advanced:
            let groups = expressionGroups.compactMap(\.expression)
            guard !groups.isEmpty else { return nil }
            return outerMode == .and ? .and(groups) : .or(groups)
        }
    }

    func addGroup() {
        let group = ExpressionGroup()
        expressionGroups.append(group)
        activeGroupID = group.id
    }

    func removeGroup(_ id: UUID) {
        expressionGroups.removeAll { $0.id == id }
        if activeGroupID == id { activeGroupID = expressionGroups.last?.id }
    }

    func setGroupMode(_ id: UUID, _ mode: MatchMode) {
        guard let index = expressionGroups.firstIndex(where: { $0.id == id }) else { return }
        expressionGroups[index].mode = mode
    }

    func removeTag(_ name: String, fromGroup id: UUID) {
        guard let index = expressionGroups.firstIndex(where: { $0.id == id }) else { return }
        expressionGroups[index].terms.removeAll { $0.name == name }
    }

    /// Flips a term between inclusion and NOT (exclusion) within its group.
    func toggleNegation(_ name: String, inGroup id: UUID) {
        guard let group = expressionGroups.firstIndex(where: { $0.id == id }),
              let term = expressionGroups[group].terms.firstIndex(where: { $0.name == name })
        else { return }
        expressionGroups[group].terms[term].negated.toggle()
    }

    /// Sidebar tag click in advanced mode: toggles the tag within the active
    /// group (creating a group first if none exists).
    func toggleTagInActiveGroup(_ name: String) {
        if expressionGroups.isEmpty { addGroup() }
        let index = expressionGroups.firstIndex(where: { $0.id == activeGroupID })
            ?? expressionGroups.indices.last!
        if expressionGroups[index].terms.contains(where: { $0.name == name }) {
            expressionGroups[index].terms.removeAll { $0.name == name }
        } else {
            expressionGroups[index].terms.append(GroupTerm(name: name))
        }
    }

    /// Whether the tag appears anywhere in the advanced expression (sidebar highlight).
    func expressionContains(_ name: String) -> Bool {
        expressionGroups.contains { $0.terms.contains { $0.name == name } }
    }

    /// The search-result row currently selected in the file list. Lives here (not
    /// in the view) so Quick Look navigation and the tag palette can follow it.
    @Published var selectedFileURL: URL?

    /// Set when writing tags to a file fails; observed by the UI to show an alert.
    @Published var tagEditError: String?

    func refreshTags() {
        tagRepository.startDiscovery()
    }

    func toggle(tag: FinderTag) {
        if selectedTagNames.contains(tag.name) {
            selectedTagNames.remove(tag.name)
        } else {
            selectedTagNames.insert(tag.name)
        }
    }

    func clearSelection() {
        switch searchMode {
        case .simple:
            selectedTagNames.removeAll()
        case .advanced:
            let empty = ExpressionGroup()
            expressionGroups = [empty]
            activeGroupID = empty.id
        }
    }

    /// True when there is nothing to clear (drives the clear button's state).
    var selectionIsEmpty: Bool {
        switch searchMode {
        case .simple: return selectedTagNames.isEmpty
        case .advanced: return expressionGroups.allSatisfy { $0.terms.isEmpty }
        }
    }

    /// Tags currently on the given search-result file (from the in-memory model).
    func tags(for url: URL) -> [String] {
        fileSearchController.files.first(where: { $0.url == url })?.tags ?? []
    }

    /// Adds or removes a Finder tag on a file: updates the in-memory model
    /// optimistically, writes the xattr, and rolls back with an error message if
    /// the write fails. `colorIndex` is only used when adding a tag that doesn't
    /// exist anywhere yet; known tags reuse their discovered color.
    func setTag(_ tagName: String, on url: URL, enabled: Bool, colorIndex: Int? = nil) {
        let currentTags = tags(for: url)
        guard enabled != currentTags.contains(tagName) else { return }

        let rawEntries = ExtendedAttributeReader.rawUserTagsPropertyList(at: url) ?? []
        let knownColor = tagRepository.tags.first(where: { $0.name == tagName })?.colorIndex
        let newEntries = enabled
            ? FinderTagWriter.addingTag(tagName, colorIndex: knownColor ?? colorIndex, to: rawEntries)
            : FinderTagWriter.removingTag(tagName, from: rawEntries)

        do {
            try FinderTagWriter.writeRawEntries(newEntries, to: url)
        } catch {
            tagEditError = error.localizedDescription
            return
        }

        let newTags = newEntries.map { FinderTagColor.parseNameAndColorIndex($0).name }
        fileSearchController.updateTags(newTags, for: url)
        tagRepository.applyLocalTagChange(
            name: tagName,
            delta: enabled ? 1 : -1,
            colorIndexIfNew: colorIndex,
            representativeIfNew: url
        )
    }

    private func runSearch() {
        fileSearchController.updateSearch(expression: currentExpression)
    }
}
