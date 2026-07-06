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

    func updateSearch(selectedTags: Set<String>, mode: MatchMode) {
        generation += 1
        let currentGeneration = generation

        guard let queryString = Self.buildQueryString(tags: selectedTags.sorted(), mode: mode) else {
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

    private func applyResults(_ items: [SpotlightQuery.Item], generation: Int) {
        guard generation == self.generation else { return }

        files = items.map { FoundFile(url: URL(fileURLWithPath: $0.path), tags: $0.tags) }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }

        isSearching = false
    }

    /// Pure query-string building logic, independent of MDQuery, so it can be unit
    /// tested against expected mdfind-syntax strings. Spotlight's multivalued-attribute
    /// semantics make `kMDItemUserTags == 'X'` mean "any tag on the file equals X",
    /// which is exactly the per-tag match needed here. Tag names are escaped via
    /// SpotlightQuery.escapeValue, never interpolated raw.
    nonisolated static func buildQueryString(tags: [String], mode: MatchMode) -> String? {
        guard !tags.isEmpty else { return nil }
        let subqueries = tags.map { "kMDItemUserTags == '\(SpotlightQuery.escapeValue($0))'" }
        guard subqueries.count > 1 else { return subqueries[0] }
        let joiner = mode == .and ? " && " : " || "
        return subqueries.joined(separator: joiner)
    }
}
