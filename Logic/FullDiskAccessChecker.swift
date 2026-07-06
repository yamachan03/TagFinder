import AppKit
import Foundation

enum FullDiskAccessChecker {
    /// Heuristic-only probe: attempts to read a well-known TCC-gated location.
    /// Not authoritative by itself -- callers should combine this with a
    /// zero-tagged-files signal from TagRepository before concluding Full Disk
    /// Access is actually missing (zero tagged files is also a legitimate, if
    /// unlikely, true state).
    static func canLikelyAccessProtectedFiles() -> Bool {
        let safariPath = NSHomeDirectory() + "/Library/Safari"
        return (try? FileManager.default.contentsOfDirectory(atPath: safariPath)) != nil
    }

    static func openFullDiskAccessSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }
}
