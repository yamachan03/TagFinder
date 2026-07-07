import AppKit
import Quartz
import SwiftUI

/// Manages the floating tag-editing palette: a non-activating utility panel that
/// can be used while the Quick Look panel stays key, so tags can be assigned
/// without interrupting arrow-key preview navigation.
@MainActor
final class TagPaletteController {
    static let shared = TagPaletteController()

    private var panel: NSPanel?
    private weak var appState: AppState?
    private weak var language: LanguageManager?

    /// Called once from ContentView.onAppear so the palette (and Quick Look's
    /// T-key forwarding) can reach the app's state objects.
    func configure(appState: AppState, language: LanguageManager) {
        self.appState = appState
        self.language = language
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() {
        if isVisible {
            panel?.orderOut(nil)
        } else {
            show()
        }
    }

    func show() {
        guard let appState, let language else { return }

        if panel == nil {
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
                styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel, .resizable],
                backing: .buffered,
                defer: true
            )
            newPanel.isFloatingPanel = true
            newPanel.level = .floating
            newPanel.hidesOnDeactivate = false
            newPanel.isReleasedWhenClosed = false
            newPanel.becomesKeyOnlyIfNeeded = true
            newPanel.contentView = NSHostingView(
                rootView: TagPaletteView()
                    .environmentObject(appState)
                    .environmentObject(language)
            )
            panel = newPanel
            positionNearQuickLookOrMainWindow(newPanel)
        }

        panel?.title = language.localized("Edit Tags")
        panel?.orderFront(nil)
    }

    /// First-show placement: beside the Quick Look panel when it's open,
    /// otherwise beside the main window. Afterwards the user's position sticks.
    private func positionNearQuickLookOrMainWindow(_ panel: NSPanel) {
        let anchorFrame: NSRect?
        if QLPreviewPanel.sharedPreviewPanelExists(), QLPreviewPanel.shared().isVisible {
            anchorFrame = QLPreviewPanel.shared().frame
        } else {
            anchorFrame = NSApp.windows.first(where: { $0.isVisible && !($0 is NSPanel) })?.frame
        }
        guard let anchorFrame else {
            panel.center()
            return
        }
        let origin = NSPoint(
            x: anchorFrame.maxX + 12,
            y: anchorFrame.maxY - panel.frame.height
        )
        panel.setFrameOrigin(origin)
        // If that lands offscreen, AppKit constrains it when ordering front.
    }
}
