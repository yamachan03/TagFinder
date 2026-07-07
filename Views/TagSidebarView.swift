import SwiftUI

struct TagSidebarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var language: LanguageManager
    @AppStorage("TagDisplayMode") private var tagDisplayModeRaw = TagDisplayMode.listWithCount.rawValue
    @State private var filterText = ""

    private var displayMode: TagDisplayMode {
        TagDisplayMode(rawValue: tagDisplayModeRaw) ?? .listWithCount
    }

    /// Tags matching the sidebar filter field. Selected tags stay selected even
    /// when the filter hides them; filtering only affects what is listed.
    private var visibleTags: [FinderTag] {
        guard !filterText.isEmpty else { return appState.tagRepository.tags }
        return appState.tagRepository.tags.filter {
            $0.name.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Search Mode", selection: $appState.searchMode) {
                ForEach(SearchMode.allCases) { mode in
                    Text(language.localized(mode.labelKey)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .top])
            .padding(.bottom, 8)

            if appState.searchMode == .simple {
                Picker("Match", selection: $appState.matchMode) {
                    ForEach(MatchMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(language.localized("Filter by tag name"), text: $filterText)
                    .textFieldStyle(.plain)
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal)
            .padding(.bottom, 8)

            if appState.tagRepository.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.tagRepository.tags.isEmpty {
                Text(language.localized("No tags found"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visibleTags.isEmpty {
                Text(language.localized("No matching tags"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch displayMode {
                case .listWithCount:
                    List(visibleTags) { tag in
                        tagRow(tag)
                    }
                    .listStyle(.sidebar)
                case .chipFlow:
                    ScrollView {
                        FlowLayout(spacing: 6) {
                            ForEach(visibleTags) { tag in
                                tagChip(tag)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Divider()

            Button(language.localized("Clear Selection")) {
                appState.clearSelection()
            }
            .disabled(appState.selectionIsEmpty)
            .padding(.vertical, 8)
        }
        .navigationTitle(language.localized("Tags"))
        .toolbar {
            ToolbarItem {
                Button {
                    appState.refreshTags()
                } label: {
                    Label(language.localized("Rescan"), systemImage: "arrow.clockwise")
                }
            }
        }
    }

    /// Selection highlight: simple mode reflects the flat selection; advanced
    /// mode highlights tags used anywhere in the expression.
    private func isHighlighted(_ tag: FinderTag) -> Bool {
        switch appState.searchMode {
        case .simple: return appState.selectedTagNames.contains(tag.name)
        case .advanced: return appState.expressionContains(tag.name)
        }
    }

    private func handleTap(_ tag: FinderTag) {
        switch appState.searchMode {
        case .simple: appState.toggle(tag: tag)
        case .advanced: appState.toggleTagInActiveGroup(tag.name)
        }
    }

    @ViewBuilder
    private func tagRow(_ tag: FinderTag) -> some View {
        let isSelected = isHighlighted(tag)
        HStack {
            Circle()
                .fill(FinderTagColor.color(for: tag.colorIndex))
                .frame(width: 10, height: 10)
            Text(tag.name)
            Spacer()
            Text("\(tag.fileCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: "checkmark")
                .foregroundStyle(.tint)
                .opacity(isSelected ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(tag)
        }
    }

    @ViewBuilder
    private func tagChip(_ tag: FinderTag) -> some View {
        let isSelected = isHighlighted(tag)
        HStack(spacing: 5) {
            Circle()
                .fill(FinderTagColor.color(for: tag.colorIndex))
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.callout)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.6)),
            in: Capsule()
        )
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .contentShape(Capsule())
        .onTapGesture {
            handleTap(tag)
        }
    }
}
