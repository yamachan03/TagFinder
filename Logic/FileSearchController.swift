import Combine
import Foundation

/// Runs a Spotlight search for files matching the selected tags, combined via
/// either AND (all selected tags) or OR (any selected tag).
@MainActor
final class FileSearchController: ObservableObject {
    @Published private(set) var files: [FoundFile] = []
    @Published private(set) var isSearching = false

    /// Incremented on every updateSearch() call so that results from a superseded
    /// search are discarded instead of overwriting newer state.
    private var generation = 0

    func updateSearch(expression: TagExpression?) {
        generation += 1
        let currentGeneration = generation

        guard let queryString = expression?.queryString else {
            files = []
            isSearching = false
            return
        }

        isSearching = true
        Task.detached(priority: .userInitiated) { [weak self] in
            let items = SpotlightQuery.runOnAllLocalVolumes(queryString) ?? []
            await self?.applyResults(items, generation: currentGeneration)
        }
    }

    /// Replaces the tag list of one result row after a local tag edit, keeping the
    /// row in place regardless of whether it still matches the current query --
    /// removing it mid-edit would be jarring; the next search reconciles.
    func updateTags(_ tags: [String], for url: URL) {
        guard let index = files.firstIndex(where: { $0.url == url }) else { return }
        files[index] = FoundFile(url: url, tags: tags)
    }

    private func applyResults(_ items: [SpotlightQuery.Item], generation: Int) {
        guard generation == self.generation else { return }

        files = items.map { FoundFile(url: URL(fileURLWithPath: $0.path), tags: $0.tags) }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }

        isSearching = false
    }

}
