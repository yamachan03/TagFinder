// Reproduction: NSMetadataQuery returns zero results for every query,
// while the MDQuery C API succeeds with the identical query string and scope.
//
// Run:  swift repro-nsmetadataquery.swift
// (Grant Full Disk Access to the host terminal, or run from any GUI app --
//  the result is the same.)

import CoreServices
import Foundation

let queryString = "kMDItemUserTags == '*'"

// --- 1. NSMetadataQuery ---------------------------------------------------
let nsQuery = NSMetadataQuery()
nsQuery.predicate = NSPredicate(format: queryString)
nsQuery.searchScopes = [NSMetadataQueryUserHomeScope]

var finished = false
let observer = NotificationCenter.default.addObserver(
    forName: .NSMetadataQueryDidFinishGathering, object: nsQuery, queue: nil
) { _ in
    print("NSMetadataQuery: resultCount = \(nsQuery.resultCount)")
    finished = true
}
nsQuery.start()
let deadline = Date().addingTimeInterval(15)
while !finished && Date() < deadline {
    RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
}
if !finished { print("NSMetadataQuery: TIMED OUT") }
NotificationCenter.default.removeObserver(observer)

// --- 2. MDQuery (same query, same scope) ----------------------------------
guard let mdQuery = MDQueryCreate(kCFAllocatorDefault, queryString as CFString, nil, nil) else {
    fatalError("MDQueryCreate failed")
}
MDQuerySetSearchScope(mdQuery, [kMDQueryScopeHome] as CFArray, 0)
_ = MDQueryExecute(mdQuery, CFOptionFlags(kMDQuerySynchronous.rawValue))
print("MDQuery:         resultCount = \(MDQueryGetResultCount(mdQuery))")
