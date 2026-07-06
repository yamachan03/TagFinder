import SwiftUI

struct TagSidebarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var filterText = ""

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
            Picker("一致条件", selection: $appState.matchMode) {
                ForEach(MatchMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .top])
            .padding(.bottom, 8)

            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("タグ名で絞り込み", text: $filterText)
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
                Text("タグが見つかりません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visibleTags.isEmpty {
                Text("一致するタグがありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(visibleTags) { tag in
                    tagRow(tag)
                }
                .listStyle(.sidebar)
            }

            Divider()

            Button("選択を解除") {
                appState.clearSelection()
            }
            .disabled(appState.selectedTagNames.isEmpty)
            .padding(.vertical, 8)
        }
        .navigationTitle("タグ")
        .toolbar {
            ToolbarItem {
                Button {
                    appState.refreshTags()
                } label: {
                    Label("再スキャン", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    @ViewBuilder
    private func tagRow(_ tag: FinderTag) -> some View {
        let isSelected = appState.selectedTagNames.contains(tag.name)
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
            appState.toggle(tag: tag)
        }
    }
}
