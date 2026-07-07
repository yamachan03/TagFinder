import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var language: LanguageManager
    @AppStorage("TagDisplayMode") private var tagDisplayModeRaw = TagDisplayMode.listWithCount.rawValue
    @AppStorage("FileDisplayMode") private var fileDisplayModeRaw = FileDisplayMode.nameAndTags.rawValue

    var body: some View {
        Form {
            Picker(language.localized("Language"), selection: $language.currentLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.radioGroup)

            Picker(language.localized("Tag Display"), selection: $tagDisplayModeRaw) {
                ForEach(TagDisplayMode.allCases) { mode in
                    Text(language.localized(mode.labelKey)).tag(mode.rawValue)
                }
            }
            .pickerStyle(.radioGroup)

            Picker(language.localized("File Display"), selection: $fileDisplayModeRaw) {
                ForEach(FileDisplayMode.allCases) { mode in
                    Text(language.localized(mode.labelKey)).tag(mode.rawValue)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding(24)
        .frame(width: 400)
    }
}
