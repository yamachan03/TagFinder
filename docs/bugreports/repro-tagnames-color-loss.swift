// Reproduction: writing tag NAMES via URL resource values destroys the
// per-file tag COLOR information stored in com.apple.metadata:_kMDItemUserTags.
//
// A read-modify-write round trip of .tagNamesKey rewrites every raw entry
// with color index 0, so a "Name\n6" (red) entry silently becomes "Name\n0".
//
// Run:  swift repro-tagnames-color-loss.swift

import Foundation

let path = NSTemporaryDirectory() + "tag-color-repro-\(UUID().uuidString).txt"
FileManager.default.createFile(atPath: path, contents: Data())
defer { try? FileManager.default.removeItem(atPath: path) }

func dumpRawEntries(_ label: String) {
    let attr = "com.apple.metadata:_kMDItemUserTags"
    let size = getxattr(path, attr, nil, 0, 0, 0)
    guard size > 0 else { print("\(label): <no xattr>"); return }
    var buf = [UInt8](repeating: 0, count: size)
    _ = getxattr(path, attr, &buf, size, 0, 0)
    let plist = try! PropertyListSerialization.propertyList(from: Data(buf), options: [], format: nil)
    print("\(label): \((plist as! [String]).map { $0.replacingOccurrences(of: "\n", with: "\\n") })")
}

// 1. Give the file a RED tag ("\n6") plus a colorless one, exactly as Finder
//    stores them in the xattr.
let entries = ["ColoredTag\n6", "PlainTag\n0"]
let data = try PropertyListSerialization.data(fromPropertyList: entries, format: .binary, options: 0)
_ = data.withUnsafeBytes {
    setxattr(path, "com.apple.metadata:_kMDItemUserTags", $0.baseAddress, data.count, 0, 0)
}
dumpRawEntries("before")

// 2. Round trip through the official API: read the names, write the SAME
//    names back (plus one addition -- the addition is not required to
//    reproduce the loss).
let url = NSURL(fileURLWithPath: path)
let names = try url.resourceValues(forKeys: [.tagNamesKey])[.tagNamesKey] as? [String] ?? []
try url.setResourceValue(names + ["AddedTag"], forKey: .tagNamesKey)

// 3. The red tag's color index has been reset to 0.
dumpRawEntries("after ")
