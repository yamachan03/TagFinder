import Combine
import Foundation

/// Discovers all Finder tags currently applied to at least one file on any local
/// mounted volume (startup disk, home, and external drives), along with a per-tag
/// file count and (best-effort) display color.
@MainActor
final class TagRepository: ObservableObject {
    @Published private(set) var tags: [FinderTag] = []
    @Published private(set) var isLoading = false
    /// Total number of tagged files seen in the last completed gather. Used by
    /// FullDiskAccessChecker as one signal (combined with its own heuristic) to decide
    /// whether to prompt the user about Full Disk Access.
    @Published private(set) var lastGatherCount = 0

    /// Incremented on every startDiscovery() call so that results from a superseded
    /// discovery run are discarded instead of overwriting newer state.
    private var generation = 0

    func startDiscovery() {
        isLoading = true
        generation += 1
        let currentGeneration = generation

        Task.detached(priority: .userInitiated) { [weak self] in
            let items = SpotlightQuery.runOnAllLocalVolumes("kMDItemUserTags == '*'") ?? []
            await self?.applyDiscovery(items, generation: currentGeneration)
        }
    }

    private func applyDiscovery(_ items: [SpotlightQuery.Item], generation: Int) {
        guard generation == self.generation else { return }

        var tagArraysPerFile: [[String]] = []
        var representativeFile: [String: URL] = [:]

        for item in items where !item.tags.isEmpty {
            tagArraysPerFile.append(item.tags)
            let url = URL(fileURLWithPath: item.path)
            for tagName in item.tags where representativeFile[tagName] == nil {
                representativeFile[tagName] = url
            }
        }

        let counts = Self.aggregate(tagArraysPerFile: tagArraysPerFile)
        lastGatherCount = tagArraysPerFile.count

        tags = counts.map { name, count in
            FinderTag(name: name, colorIndex: Self.colorIndex(forTag: name, representativeFile: representativeFile), fileCount: count)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        isLoading = false
    }

    private static func colorIndex(forTag name: String, representativeFile: [String: URL]) -> Int? {
        guard let url = representativeFile[name],
              let entries = ExtendedAttributeReader.rawUserTagsPropertyList(at: url) else { return nil }
        for entry in entries {
            let parsed = FinderTagColor.parseNameAndColorIndex(entry)
            if parsed.name == name { return parsed.colorIndex }
        }
        return nil
    }

    /// Pure aggregation logic, independent of Spotlight, so it can be unit tested
    /// with synthetic fixtures instead of the real index.
    nonisolated static func aggregate(tagArraysPerFile: [[String]]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for tagsOnFile in tagArraysPerFile {
            for tag in Set(tagsOnFile) {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }
}
