import XCTest
@testable import TagFinder

final class TagRepositoryTests: XCTestCase {
    func testAggregateCountsEachTagAcrossFiles() {
        let fixture: [[String]] = [
            ["Work", "Urgent"],
            ["Work"],
            ["Personal", "Urgent"],
            ["Work", "Personal", "Urgent"],
            [],
        ]
        let counts = TagRepository.aggregate(tagArraysPerFile: fixture)
        XCTAssertEqual(counts["Work"], 3)
        XCTAssertEqual(counts["Urgent"], 3)
        XCTAssertEqual(counts["Personal"], 2)
        XCTAssertNil(counts["Nonexistent"])
    }

    func testAggregateOfEmptyInputIsEmpty() {
        XCTAssertTrue(TagRepository.aggregate(tagArraysPerFile: []).isEmpty)
    }

    func testDuplicateTagOnSameFileIsCountedOnce() {
        // A malformed/duplicate tag entry on a single file should not inflate that
        // tag's file count beyond the number of distinct files it appears on.
        let fixture: [[String]] = [["Work", "Work"]]
        let counts = TagRepository.aggregate(tagArraysPerFile: fixture)
        XCTAssertEqual(counts["Work"], 1)
    }

    func testTagNamesAreCaseSensitive() {
        // "Work" and "work" are treated as distinct tags, matching Spotlight's
        // exact-string comparison for kMDItemUserTags.
        let fixture: [[String]] = [["Work"], ["work"]]
        let counts = TagRepository.aggregate(tagArraysPerFile: fixture)
        XCTAssertEqual(counts["Work"], 1)
        XCTAssertEqual(counts["work"], 1)
    }
}
