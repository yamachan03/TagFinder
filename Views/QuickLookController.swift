import AppKit
import Quartz

/// Drives the shared QLPreviewPanel for the search-result list, Finder-style:
/// the panel previews the current collection, and arrow keys pressed while the
/// panel is key are forwarded back so the list selection stays in sync.
///
/// QLPreviewPanel only accepts a dataSource/delegate through the responder-chain
/// controller protocol (`acceptsPreviewPanelControl` etc., implemented on
/// AppDelegate), which hands control to this shared instance when the panel is
/// shown. The SwiftUI `.quickLookPreview` modifier is not used because the panel
/// owns key events while open -- up/down arrows would neither navigate the
/// preview nor move the list selection.
final class QuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookController()

    private var urls: [URL] = []
    /// Called whenever panel navigation (arrow keys) moves to another item, so
    /// the owning view can move its list selection to match.
    var onCurrentItemChange: ((URL) -> Void)?

    var isVisible: Bool {
        QLPreviewPanel.sharedPreviewPanelExists() && QLPreviewPanel.shared().isVisible
    }

    func present(urls: [URL], currentItem: URL) {
        self.urls = urls
        guard let panel = QLPreviewPanel.shared() else { return }
        // Ordering front walks the responder chain and reaches AppDelegate's
        // beginPreviewPanelControl, which installs this instance as
        // dataSource/delegate -- only then may the panel be configured.
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
        panel.currentPreviewItemIndex = urls.firstIndex(of: currentItem) ?? 0
    }

    func close() {
        guard isVisible else { return }
        QLPreviewPanel.shared().orderOut(nil)
    }

    /// Follows an external selection change (e.g. the user clicked another row
    /// while the panel is open).
    func updateCurrentItem(_ url: URL) {
        guard isVisible,
              let panel = QLPreviewPanel.shared(),
              let index = urls.firstIndex(of: url),
              panel.currentPreviewItemIndex != index else { return }
        panel.currentPreviewItemIndex = index
    }

    // MARK: - QLPreviewPanelDataSource

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }

    // MARK: - QLPreviewPanelDelegate

    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        guard event.type == .keyDown else { return false }
        switch event.keyCode {
        case 125, 124: // down, right -> next
            step(1, panel: panel)
            return true
        case 126, 123: // up, left -> previous
            step(-1, panel: panel)
            return true
        case 49: // space toggles the panel closed, like Finder
            close()
            return true
        default:
            return false
        }
    }

    private func step(_ delta: Int, panel: QLPreviewPanel) {
        guard !urls.isEmpty else { return }
        let newIndex = max(0, min(urls.count - 1, panel.currentPreviewItemIndex + delta))
        guard newIndex != panel.currentPreviewItemIndex else { return }
        panel.currentPreviewItemIndex = newIndex
        onCurrentItemChange?(urls[newIndex])
    }
}
