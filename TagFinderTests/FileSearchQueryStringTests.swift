import XCTest
@testable import TagFinder

/// True end-to-end AND/OR matching against real files can only be verified against
/// the live Spotlight index (see the plan's manual verification matrix, confirmed
/// empirically against the 5-file fixture with mdfind and MDQuery). These tests
/// verify the part actually under this app's control: the exact mdfind-syntax query
/// string `buildQueryString` constructs, including safe escaping of tag names.
final class FileSearchQueryStringTests: XCTestCase {
    func testEmptyTagsReturnsNil() {
        XCTAssertNil(FileSearchController.buildQueryString(tags: [], mode: .and))
        XCTAssertNil(FileSearchController.buildQueryString(tags: [], mode: .or))
    }

    func testSingleTagBuildsPlainComparison() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["Work"], mode: .and),
            "kMDItemUserTags == 'Work'"
        )
    }

    func testSingleTagIsIdenticalRegardlessOfMode() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["Work"], mode: .and),
            FileSearchController.buildQueryString(tags: ["Work"], mode: .or)
        )
    }

    func testMultipleTagsAndModeJoinsWithConjunction() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["Work", "Urgent"], mode: .and),
            "kMDItemUserTags == 'Work' && kMDItemUserTags == 'Urgent'"
        )
    }

    func testMultipleTagsOrModeJoinsWithDisjunction() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["Work", "Urgent"], mode: .or),
            "kMDItemUserTags == 'Work' || kMDItemUserTags == 'Urgent'"
        )
    }

    func testThreeTagsProduceThreeClausesInInputOrder() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["Work", "Personal", "Urgent"], mode: .and),
            "kMDItemUserTags == 'Work' && kMDItemUserTags == 'Personal' && kMDItemUserTags == 'Urgent'"
        )
    }

    func testDuplicateTagNamesStillProduceOneClauseEach() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["Work", "Work"], mode: .and),
            "kMDItemUserTags == 'Work' && kMDItemUserTags == 'Work'"
        )
    }

    func testSingleQuoteInTagNameIsEscaped() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["O'Brien"], mode: .and),
            "kMDItemUserTags == 'O\\'Brien'"
        )
    }

    func testBackslashInTagNameIsEscapedBeforeQuotes() {
        // A literal backslash must become \\ and a literal quote \' -- escaping
        // backslashes first ensures the quote's escape backslash isn't re-escaped.
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["back\\slash'quote"], mode: .and),
            "kMDItemUserTags == 'back\\\\slash\\'quote'"
        )
    }

    func testUnicodeTagNamePassesThroughUnchanged() {
        XCTAssertEqual(
            FileSearchController.buildQueryString(tags: ["酷い騒音"], mode: .and),
            "kMDItemUserTags == '酷い騒音'"
        )
    }
}
