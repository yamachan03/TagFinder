import AppKit
import SwiftUI

struct FileListView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var language: LanguageManager
    @State private var filterText: String = ""
    @State private var selectedFileURL: URL?
    private let quickLook = QuickLookController.shared

    private var tagColorLookup: [String: Int?] {
        Dictionary(uniqueKeysWithValues: appState.tagRepository.tags.map { ($0.name, $0.colorIndex) })
    }

    private var filteredFiles: [FoundFile] {
        guard !filterText.isEmpty else { return appState.fileSearchController.files }
        return appState.fileSearchController.files.filter {
            $0.displayName.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .searchable(text: $filterText, prompt: Text(language.localized("Filter by file name")))
    }

    @ViewBuilder
    private var header: some View {
        if !appState.selectedTagNames.isEmpty {
            HStack {
                Text(headerText)
                    .font(.headline)
                Spacer()
            }
            .padding()
        }
    }

    private var headerText: String {
        let joiner = appState.matchMode == .and ? " AND " : " OR "
        let tagList = appState.selectedTagNames.sorted().joined(separator: joiner)
        return language.localizedDynamic("Header Items", args: [tagList, String(filteredFiles.count)])
    }

    @ViewBuilder
    private var content: some View {
        if appState.selectedTagNames.isEmpty {
            emptyState(message: language.localized("Select tags to search"))
        } else if appState.fileSearchController.isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredFiles.isEmpty {
            emptyState(message: language.localized("No matching files"))
        } else {
            List(filteredFiles, selection: $selectedFileURL) { file in
                fileRow(file)
                    .tag(file.url)
            }
            // Row-level tap gestures would intercept single clicks and break List
            // selection, so double-click (primaryAction) and the right-click menu
            // are attached selection-based instead.
            .contextMenu(forSelectionType: URL.self) { urls in
                Button(language.localized("Reveal in Finder")) {
                    NSWorkspace.shared.activateFileViewerSelecting(Array(urls))
                }
                Button(language.localized("Open")) {
                    for url in urls { NSWorkspace.shared.open(url) }
                }
                Button(language.localized("Copy Path")) {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(urls.map(\.path).joined(separator: "\n"), forType: .string)
                }
            } primaryAction: { urls in
                for url in urls { NSWorkspace.shared.open(url) }
            }
            .onKeyPress(.space) {
                guard let selectedFileURL else { return .ignored }
                if quickLook.isVisible {
                    quickLook.close()
                } else {
                    quickLook.onCurrentItemChange = { self.selectedFileURL = $0 }
                    quickLook.present(urls: filteredFiles.map(\.url), currentItem: selectedFileURL)
                }
                return .handled
            }
            .onChange(of: selectedFileURL) { _, newValue in
                guard let newValue else { return }
                quickLook.updateCurrentItem(newValue)
            }
        }
    }

    private func emptyState(message: String) -> some View {
        Text(message)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func fileRow(_ file: FoundFile) -> some View {
        HStack {
            Image(nsImage: file.icon)
                .resizable()
                .frame(width: 24, height: 24)
            VStack(alignment: .leading) {
                Text(file.displayName)
                Text(file.containingFolder)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(file.tags, id: \.self) { tagName in
                    TagChipView(name: tagName, colorIndex: tagColorLookup[tagName] ?? nil)
                }
            }
        }
    }
}
