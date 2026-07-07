import SwiftUI

/// Advanced-search condition area shown above the results: one card per group
/// (flat AND/OR of tags), groups combined by the outer operator. Clicking a
/// card makes it the active target for sidebar tag clicks.
struct ExpressionBuilderView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var language: LanguageManager

    private var tagColorLookup: [String: Int?] {
        Dictionary(uniqueKeysWithValues: appState.tagRepository.tags.map { ($0.name, $0.colorIndex) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(language.localized("Groups combined with"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $appState.outerMode) {
                    ForEach(MatchMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 110)
                Spacer()
                Button {
                    appState.addGroup()
                } label: {
                    Label(language.localized("Add Group"), systemImage: "plus")
                }
            }

            ForEach(appState.expressionGroups) { group in
                groupCard(group)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func groupCard(_ group: ExpressionGroup) -> some View {
        let isActive = appState.activeGroupID == group.id
        HStack(alignment: .center, spacing: 8) {
            Picker("", selection: Binding(
                get: { group.mode },
                set: { appState.setGroupMode(group.id, $0) }
            )) {
                ForEach(MatchMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 100)

            if group.tags.isEmpty {
                Text(language.localized("Click sidebar tags to add"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 4) {
                    ForEach(group.tags, id: \.self) { name in
                        groupTagChip(name, groupID: group.id)
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                appState.removeGroup(group.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isActive ? Color.accentColor : Color.gray.opacity(0.35),
                    lineWidth: isActive ? 2 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appState.activeGroupID = group.id
        }
    }

    @ViewBuilder
    private func groupTagChip(_ name: String, groupID: UUID) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(FinderTagColor.color(for: tagColorLookup[name] ?? nil))
                .frame(width: 7, height: 7)
            Text(name)
                .font(.callout)
                .lineLimit(1)
            Image(systemName: "xmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.6), in: Capsule())
        .contentShape(Capsule())
        .onTapGesture {
            appState.removeTag(name, fromGroup: groupID)
        }
    }
}
