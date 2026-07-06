import SwiftUI

/// Pure parsing/mapping logic, deliberately free of any file I/O so it can be unit
/// tested without touching disk or Spotlight.
enum FinderTagColor {
    /// Parses a raw xattr entry like `"Work\n2"` into its tag name and Finder color
    /// index. Entries with no color suffix (just the tag name) are valid too.
    static func parseNameAndColorIndex(_ rawEntry: String) -> (name: String, colorIndex: Int?) {
        let parts = rawEntry.split(separator: "\n", maxSplits: 1)
        guard parts.count == 2, let index = Int(parts[1]) else {
            return (name: parts.first.map(String.init) ?? rawEntry, colorIndex: nil)
        }
        return (name: String(parts[0]), colorIndex: index)
    }

    /// Maps a Finder tag color index (0-7) to a display color.
    ///
    /// NOTE: this ordering is a hypothesis carried over from the legacy Finder label
    /// color order (None, Gray, Green, Purple, Blue, Yellow, Red, Orange). Verify it
    /// empirically against real tagged files and Finder's own color swatches before
    /// relying on it (see plan Phase 2) and adjust this table if it's wrong.
    private static let colorTable: [Color] = [
        .gray,    // 0 - none
        .gray,    // 1 - gray
        .green,   // 2 - green
        .purple,  // 3 - purple
        .blue,    // 4 - blue
        .yellow,  // 5 - yellow
        .red,     // 6 - red
        .orange,  // 7 - orange
    ]

    static func color(for colorIndex: Int?) -> Color {
        guard let colorIndex, colorTable.indices.contains(colorIndex) else {
            return .gray
        }
        return colorTable[colorIndex]
    }
}
