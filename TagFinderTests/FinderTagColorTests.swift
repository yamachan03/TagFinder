import XCTest
@testable import TagFinder

final class FinderTagColorTests: XCTestCase {
    func testParseWellFormedEntry() {
        let result = FinderTagColor.parseNameAndColorIndex("Work\n2")
        XCTAssertEqual(result.name, "Work")
        XCTAssertEqual(result.colorIndex, 2)
    }

    func testParseEntryWithNoColorSuffix() {
        let result = FinderTagColor.parseNameAndColorIndex("Work")
        XCTAssertEqual(result.name, "Work")
        XCTAssertNil(result.colorIndex)
    }

    func testParseEntryWithNonNumericSuffixTreatsWholeStringAsFallback() {
        let result = FinderTagColor.parseNameAndColorIndex("Work\nred")
        XCTAssertNil(result.colorIndex)
    }

    func testParseEmptyStringDoesNotCrash() {
        let result = FinderTagColor.parseNameAndColorIndex("")
        XCTAssertEqual(result.name, "")
        XCTAssertNil(result.colorIndex)
    }

    func testParseOutOfRangeIndexStillParsesAsInt() {
        let result = FinderTagColor.parseNameAndColorIndex("Weird\n99")
        XCTAssertEqual(result.name, "Weird")
        XCTAssertEqual(result.colorIndex, 99)
    }

    func testParseMultiWordAndUnicodeNames() {
        let result = FinderTagColor.parseNameAndColorIndex("重要\n6")
        XCTAssertEqual(result.name, "重要")
        XCTAssertEqual(result.colorIndex, 6)
    }

    func testColorForEachValidIndexDoesNotFallBackToDefault() {
        for index in 0...7 {
            // Every in-range index should resolve without hitting the nil/out-of-range fallback path.
            _ = FinderTagColor.color(for: index)
        }
    }

    func testColorForOutOfRangeIndexFallsBackToGray() {
        XCTAssertEqual(FinderTagColor.color(for: 8), .gray)
        XCTAssertEqual(FinderTagColor.color(for: -1), .gray)
    }

    func testColorForNilFallsBackToGray() {
        XCTAssertEqual(FinderTagColor.color(for: nil), .gray)
    }
}
