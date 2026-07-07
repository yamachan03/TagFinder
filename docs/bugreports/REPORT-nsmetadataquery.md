# Feedback Assistant report — NSMetadataQuery returns zero results

**Title:**
NSMetadataQuery returns zero results for every query, while MDQuery / mdfind succeed with the identical query and scope

**Area:** macOS / Foundation (Spotlight metadata queries)

**Environment:** macOS 26.5.1 (25F80), Mac Studio (Mac13,1)

---

## Description

On macOS 26.5.1, `NSMetadataQuery` returns zero results for **every** predicate
and search scope we tried, in every process type:

- a plain command-line Swift process (host terminal has Full Disk Access, run loop pumping),
- a signed, hardened-runtime GUI app with Full Disk Access granted,
- with scopes `NSMetadataQueryUserHomeScope`, explicit folder paths, and no scope,
- with predicates such as `kMDItemUserTags == '*'`, `kMDItemFSName LIKE '*'`, and `NSPredicate(value: true)`.

`NSMetadataQueryDidFinishGathering` fires normally, but `resultCount` is always 0.

The **same query string with the same scope** succeeds when issued through the
lower-level `MDQuery` C API (`MDQueryCreate` / `MDQueryExecute`), and through
`mdfind` on the command line. Spotlight indexing itself is healthy
(`mdutil -s /` reports indexing enabled; Finder and Spotlight search work).

This breaks any third-party app that relies on NSMetadataQuery for Spotlight
searches (in our case: enumerating files by Finder tag).

## Steps to reproduce

1. Save the attached `repro-nsmetadataquery.swift`.
2. Ensure at least one file in your home directory has a Finder tag.
3. Run: `swift repro-nsmetadataquery.swift` (grant Full Disk Access to the
   terminal if prompted; the result is identical from a GUI app).

## Expected result

Both counts are equal and non-zero.

## Actual result

```
NSMetadataQuery: resultCount = 0
MDQuery:         resultCount = 30
```

(30 = number of tagged files in this home directory; MDQuery and mdfind agree.)

## Notes

- Reproduces 100% of the time on this machine.
- Not a TCC issue: the same process can read TCC-protected paths directly
  (e.g. `~/Library/Mail`), and the MDQuery result proves the metadata store is
  reachable from the same process.
- Attachment: `repro-nsmetadataquery.swift`
