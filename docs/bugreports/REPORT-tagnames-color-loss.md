# Feedback Assistant report — .tagNamesKey destroys tag colors

**Title:**
Setting URL resource value .tagNamesKey silently destroys Finder tag color information (per-file color indexes reset to 0)

**Area:** macOS / Foundation (Files & Storage — URL resource values / Finder tags)

**Environment:** macOS 26.5.1 (25F80), Mac Studio (Mac13,1)

---

## Description

Finder stores tags in the `com.apple.metadata:_kMDItemUserTags` extended
attribute as a plist array of `"Name\n<colorIndex>"` strings, where the suffix
carries the tag's color.

Writing tag **names** through the official API —
`NSURL.setResourceValue(_:forKey: .tagNamesKey)` (or
`URLResourceValues.tagNames` via `setResourceValues`) — rewrites **every**
entry with color index 0. A plain read-modify-write round trip of the names is
enough to reproduce: a `"ColoredTag\n6"` (red) entry comes back as
`"ColoredTag\n0"` (no color).

Because the API accepts names only, there is no way to preserve — let alone
set — the colors through the documented interface. Any app that edits tags via
resource values silently strips color information the user assigned in Finder.
The destructive behavior is not documented.

## Steps to reproduce

1. Save the attached `repro-tagnames-color-loss.swift`.
2. Run: `swift repro-tagnames-color-loss.swift`

The script creates a temp file, writes a red tag entry (`"ColoredTag\n6"`)
into the xattr exactly as Finder does, reads `.tagNamesKey`, writes the same
names back, and dumps the raw entries before and after.

## Expected result

Entries that were already on the file keep their color suffixes; at minimum,
the color-destroying behavior should be documented.

```
before: ["ColoredTag\n6", "PlainTag\n0"]
after : ["ColoredTag\n6", "PlainTag\n0", "AddedTag\n0"]
```

## Actual result

```
before: ["ColoredTag\n6", "PlainTag\n0"]
after : ["ColoredTag\n0", "PlainTag\n0", "AddedTag\n0"]
```

## Notes

- Reproduces 100% of the time.
- Workaround we ship: edit the raw xattr directly and preserve existing
  entries byte-for-byte, bypassing `.tagNamesKey` entirely.
- Attachment: `repro-tagnames-color-loss.swift`
