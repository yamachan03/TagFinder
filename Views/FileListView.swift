import AppKit
import SwiftUI

struct FileListView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var language: LanguageManager
    @AppStorage("FileDisplayMode") private var fileDisplayModeRaw = FileDisplayMode.nameAndTags.rawValue
    @State private var filterText: String = ""
    @State private var hoveredFileURL: URL?
    @State private var showingSaveSearchDialog = false
    @State private var newSearchName = ""
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
            if appState.searchMode == .advanced {
                ExpressionBuilderView()
                Divider()
            }
            header
            Divider()
            content
        }
        .searchable(text: $filterText, prompt: Text(language.localized("Filter by file name")))
        // Toolbar and dialogs live on the outer container, not the List branch,
        // so they don't vanish when the results area shows an empty state.
        .toolbar {
            ToolbarItem {
                Menu {
                    if appState.savedSearches.isEmpty {
                        Text(language.localized("No saved searches"))
                    } else {
                        ForEach(appState.savedSearches) { saved in
                            Button(saved.name) {
                                appState.applySavedSearch(saved)
                            }
                            .help(saved.expression?.displayString ?? "")
                        }
                    }
                    Divider()
                    Button(language.localized("Save Current Search…")) {
                        newSearchName = ""
                        showingSaveSearchDialog = true
                    }
                    .disabled(appState.currentExpression == nil)
                    if !appState.savedSearches.isEmpty {
                        Menu(language.localized("Delete Saved Search")) {
                            ForEach(appState.savedSearches) { saved in
                                Button(saved.name, role: .destructive) {
                                    appState.deleteSavedSearch(saved.id)
                                }
                            }
                        }
                    }
                } label: {
                    Label(language.localized("Saved Searches"), systemImage: "bookmark")
                }
            }
            ToolbarItem {
                Button {
                    TagPaletteController.shared.toggle()
                } label: {
                    Label(language.localized("Edit Tags"), systemImage: "tag")
                }
                .disabled(appState.selectedFileURL == nil)
            }
        }
        .alert(language.localized("Save Current Search"), isPresented: $showingSaveSearchDialog) {
            TextField(language.localized("Search name"), text: $newSearchName)
            Button(language.localized("Save")) {
                appState.saveCurrentSearch(named: newSearchName)
            }
            Button(language.localized("Cancel"), role: .cancel) {}
        } message: {
            Text(appState.currentExpression?.displayString ?? "")
        }
    }

    @ViewBuilder
    private var header: some View {
        if appState.currentExpression != nil {
            HStack {
                Text(headerText)
                    .font(.headline)
                Spacer()
            }
            .padding()
        }
    }

    private var headerText: String {
        let formula = appState.currentExpression?.displayString ?? ""
        return language.localizedDynamic("Header Items", args: [formula, String(filteredFiles.count)])
    }

    @ViewBuilder
    private var content: some View {
        if appState.currentExpression == nil {
            emptyState(message: language.localized("Select tags to search"))
        } else if appState.fileSearchController.isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredFiles.isEmpty {
            emptyState(message: language.localized("No matching files"))
        } else {
            List(filteredFiles, selection: $appState.selectedFileURL) { file in
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
                guard let selectedFileURL = appState.selectedFileURL else { return .ignored }
                if quickLook.isVisible {
                    quickLook.close()
                } else {
                    quickLook.onCurrentItemChange = { appState.selectedFileURL = $0 }
                    quickLook.present(urls: filteredFiles.map(\.url), currentItem: selectedFileURL)
                }
                return .handled
            }
            .onChange(of: appState.selectedFileURL) { _, newValue in
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
        // In name-only mode the chips stay hidden but reappear for the row
        // under the mouse, so tags can still be checked without switching modes.
        let displayMode = FileDisplayMode(rawValue: fileDisplayModeRaw) ?? .nameAndTags
        let showsTags = displayMode == .nameAndTags || hoveredFileURL == file.url
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
            if showsTags {
                HStack(spacing: 6) {
                    ForEach(file.tags, id: \.self) { tagName in
                        TagChipView(name: tagName, colorIndex: tagColorLookup[tagName] ?? nil)
                    }
                }
            }
        }
        .onHover { hovering in
            if hovering {
                hoveredFileURL = file.url
            } else if hoveredFileURL == file.url {
                hoveredFileURL = nil
            }
        }
    }
}
