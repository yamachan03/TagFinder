import Quartz
import SwiftUI

@main
struct TagFinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var language = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(language)
        }
        .commands {
            CommandGroup(after: .pasteboard) {
                Button(language.localized("Edit Tags")) {
                    TagPaletteController.shared.toggle()
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
        Settings {
            SettingsView()
                .environmentObject(language)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // MARK: - QLPreviewPanel controller protocol
    // QLPreviewPanel searches the responder chain for a controller; without one
    // it ignores its dataSource and never shows content. The app delegate is the
    // chain's last stop, so panel control is accepted here and handed to the
    // shared QuickLookController.

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        true
    }

    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = QuickLookController.shared
        panel.delegate = QuickLookController.shared
    }

    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = nil
        panel.delegate = nil
    }
}
