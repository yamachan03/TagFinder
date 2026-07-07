import SwiftUI

/// Contents of the floating tag palette: shows every known tag as a chip, with
/// the ones assigned to the currently selected file highlighted. Clicking a chip
/// toggles the tag on the file; a brand-new tag can be created with a color.
struct TagPaletteView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var language: LanguageManager
    @State private var filterText = ""
    @State private var newTagName = ""
    @State private var newTagColorIndex = 0

    /// The file being edited: the Quick Look panel's current item takes priority
    /// while the panel is open (the list selection normally tracks it anyway, but
    /// can be cleared independently); otherwise the list selection.
    private var targetURL: URL? {
        QuickLookController.shared.currentItemURL ?? appState.selectedFileURL
    }

    private var currentTags: Set<String> {
        guard let targetURL else { return [] }
        return Set(appState.tags(for: targetURL))
    }

    private var visibleTags: [FinderTag] {
        guard !filterText.isEmpty else { return appState.tagRepository.tags }
        return appState.tagRepository.tags.filter {
            $0.name.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(targetURL?.lastPathComponent ?? language.localized("No file selected"))
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)

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

            ScrollView {
                FlowLayout(spacing: 6) {
                    ForEach(visibleTags) { tag in
                        paletteChip(tag)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(targetURL == nil ? 0.4 : 1)

            Divider()

            HStack(spacing: 6) {
                TextField(language.localized("New tag name"), text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addNewTag)
                colorPicker
                Button(language.localized("Add"), action: addNewTag)
                    .disabled(newTagName.isEmpty || targetURL == nil)
            }
            .padding(10)
        }
        .frame(minWidth: 280, minHeight: 300)
    }

    @ViewBuilder
    private func paletteChip(_ tag: FinderTag) -> some View {
        let isOn = currentTags.contains(tag.name)
        HStack(spacing: 5) {
            Circle()
                .fill(FinderTagColor.color(for: tag.colorIndex))
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.callout)
                .lineLimit(1)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.caption2.bold())
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.6)),
            in: Capsule()
        )
        .foregroundStyle(isOn ? Color.white : Color.primary)
        .contentShape(Capsule())
        .onTapGesture {
            guard let targetURL else { return }
            appState.setTag(tag.name, on: targetURL, enabled: !isOn)
        }
    }

    /// Compact picker of the Finder tag colors (0 = none, 1-7 = colors) for a
    /// newly created tag.
    private var colorPicker: some View {
        HStack(spacing: 3) {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(FinderTagColor.color(for: index))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: newTagColorIndex == index ? 1.5 : 0)
                    )
                    .contentShape(Circle())
                    .onTapGesture { newTagColorIndex = index }
            }
        }
    }

    private func addNewTag() {
        guard let targetURL, !newTagName.isEmpty else { return }
        appState.setTag(newTagName, on: targetURL, enabled: true, colorIndex: newTagColorIndex)
        newTagName = ""
    }
}
