import Combine
import SwiftUI

/// Supported UI languages. Adding a language = add a case here plus a column in
/// `LanguageManager.strings` (same convention as the sibling MP4Merger project).
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "AppLanguage") ?? "ja"
        self.currentLanguage = AppLanguage(rawValue: saved) ?? .japanese
    }

    /// English text doubles as the lookup key, mirroring MP4Merger's convention.
    static let strings: [String: [AppLanguage: String]] = [
        // Sidebar
        "Tags": [.english: "Tags", .japanese: "タグ"],
        "Filter by tag name": [.english: "Filter by tag name", .japanese: "タグ名で絞り込み"],
        "No tags found": [.english: "No tags found", .japanese: "タグが見つかりません"],
        "No matching tags": [.english: "No matching tags", .japanese: "一致するタグがありません"],
        "Clear Selection": [.english: "Clear Selection", .japanese: "選択を解除"],
        "Rescan": [.english: "Rescan", .japanese: "再スキャン"],

        // File list
        "Filter by file name": [.english: "Filter by file name", .japanese: "ファイル名で絞り込み"],
        "Select tags to search": [.english: "Select tags to search files", .japanese: "タグを選択してください"],
        "No matching files": [.english: "No matching files", .japanese: "一致するファイルがありません"],
        "Reveal in Finder": [.english: "Reveal in Finder", .japanese: "Finderで表示"],
        "Open": [.english: "Open", .japanese: "開く"],
        "Copy Path": [.english: "Copy Path", .japanese: "パスをコピー"],
        "Header Items": [.english: "{0} · {1} items", .japanese: "{0} · {1}件"],

        // Full Disk Access prompt
        "Full Disk Access Required": [.english: "Full Disk Access Required", .japanese: "フルディスクアクセスが必要です"],
        "FDA Description": [
            .english: "To search Finder tags on all volumes (including external drives), please allow Full Disk Access for TagFinder in System Settings.",
            .japanese: "TagFinderがすべてのボリューム（外付けドライブ含む）のFinderタグを検索するには、システム設定でフルディスクアクセスを許可してください。",
        ],
        "Open System Settings": [.english: "Open System Settings", .japanese: "システム設定を開く"],

        // Settings
        "Language": [.english: "Language", .japanese: "言語"],
        "Tag Display": [.english: "Tag Display", .japanese: "タグの表示"],
        "List with file counts": [.english: "List with file counts", .japanese: "件数付きリスト"],
        "Tags only (wrap)": [.english: "Tags only (wrapped)", .japanese: "タグのみ（折り返し表示）"],
        "File Display": [.english: "File Display", .japanese: "ファイルの表示"],
        "Name, path, and tags": [.english: "Name, path, and tags", .japanese: "名前・パス・タグ"],
        "Name and path only": [.english: "Name and path only", .japanese: "名前・パスのみ"],

        // Advanced search (expression builder)
        "Simple": [.english: "Simple", .japanese: "シンプル"],
        "Advanced": [.english: "Advanced", .japanese: "詳細"],
        "Add Group": [.english: "Add Group", .japanese: "グループを追加"],
        "Groups combined with": [.english: "Combine groups with", .japanese: "グループ間の結合"],
        "Click sidebar tags to add": [.english: "Click tags in the sidebar to add", .japanese: "サイドバーのタグをクリックして追加"],

        // Tag palette
        "Edit Tags": [.english: "Edit Tags", .japanese: "タグを編集"],
        "No file selected": [.english: "No file selected", .japanese: "ファイルが選択されていません"],
        "New tag name": [.english: "New tag name", .japanese: "新規タグ名"],
        "Add": [.english: "Add", .japanese: "追加"],
        "Could not update tags": [.english: "Could not update tags", .japanese: "タグを更新できませんでした"],
    ]

    func localized(_ key: String) -> String {
        guard let translations = Self.strings[key] else { return key }
        return translations[currentLanguage] ?? translations[.english] ?? key
    }

    func localizedDynamic(_ baseKey: String, args: [String]) -> String {
        var str = localized(baseKey)
        for (i, arg) in args.enumerated() {
            str = str.replacingOccurrences(of: "{\(i)}", with: arg)
        }
        return str
    }
}
