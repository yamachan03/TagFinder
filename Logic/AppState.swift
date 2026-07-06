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

    private func runSearch() {
        fileSearchController.updateSearch(selectedTags: selectedTagNames, mode: matchMode)
    }
}
