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
        selectedTagNames.removeAll()
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
        fileSearchController.updateSearch(selectedTags: selectedTagNames, mode: matchMode)
    }
}
