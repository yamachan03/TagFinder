# TagFinder

[日本語](README.ja.md)

A macOS app for searching files by their Finder tags. Pick multiple tags from the sidebar and narrow down files with AND (has all selected tags) / OR (has any selected tag) matching.

## Features

- Lists every Finder tag on all local volumes (including external drives) with file counts
- AND / OR filtering by multiple selected tags
- Advanced search mode: build compound boolean expressions like `(A AND B) OR (C AND D) OR E` with a group-based condition builder
- Incremental filtering by tag name and by file name
- Quick Look preview: select a result and press the space bar (up/down arrows switch the previewed file)
- Tag editing palette (toolbar button, Cmd+T, or T while Quick Look is open): toggle existing tags on the previewed file, or create a new tag with a color — existing tag colors on the file are preserved
- Double-click to open, right-click for "Reveal in Finder" / "Copy Path"
- Settings (Cmd+,): switch the UI language (Japanese / English), the sidebar tag display (list with file counts, or compact wrapped chips), and the result rows (with all tags on each file, or name and path only — tags still appear when hovering a row)

## Requirements

- macOS 15.6 or later
- **Full Disk Access** permission (System Settings > Privacy & Security > Full Disk Access)
  - Required to search tags outside your home folder and on external volumes via Spotlight
- Spotlight indexing must be enabled on the volumes you want to search

## Building

Open `TagFinder.xcodeproj` in Xcode and build. The project file is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen), so re-run `xcodegen` after changing the file layout.

```sh
xcodegen                                       # regenerate project (only after adding files)
xcodebuild -scheme TagFinder -configuration Release build
```

## Implementation notes

Spotlight queries go through the low-level **MDQuery C API** (`Logic/SpotlightQuery.swift`) — the same engine `mdfind` uses — instead of `NSMetadataQuery`. On the development machine (macOS 26.5), `NSMetadataQuery` returns zero results for every query even with Full Disk Access granted. Query-string construction, tag aggregation, and tag-color parsing are covered by unit tests.

## License

[MIT License](LICENSE)
