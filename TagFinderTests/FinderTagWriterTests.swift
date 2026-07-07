import XCTest
@testable import TagFinder

final class FinderTagWriterTests: XCTestCase {
    // MARK: - addingTag

    func testAddingTagToEmptyList() {
        XCTAssertEqual(
            FinderTagWriter.addingTag("Work", colorIndex: nil, to: []),
            ["Work\n0"]
        )
    }

    func testAddingTagWithColorUsesColorSuffix() {
        XCTAssertEqual(
            FinderTagWriter.addingTag("Important", colorIndex: 6, to: []),
            ["Important\n6"]
        )
    }

    func testAddingTagPreservesExistingColoredEntriesUntouched() {
        let existing = ["Red\n6", "Plain\n0", "BareForm"]
        XCTAssertEqual(
            FinderTagWriter.addingTag("New", colorIndex: 2, to: existing),
            ["Red\n6", "Plain\n0", "BareForm", "New\n2"]
        )
    }

    func testAddingDuplicateTagIsNoOp() {
        let existing = ["Work\n0", "Urgent\n0"]
        XCTAssertEqual(
            FinderTagWriter.addingTag("Work", colorIndex: 3, to: existing),
            existing
        )
    }

    func testAddingDuplicateOfBareFormEntryIsNoOp() {
        let existing = ["Work", "Urgent\n0"]
        XCTAssertEqual(
            FinderTagWriter.addingTag("Work", colorIndex: nil, to: existing),
            existing
        )
    }

    func testAddingUnicodeTagName() {
        XCTAssertEqual(
            FinderTagWriter.addingTag("酷い騒音", colorIndex: nil, to: []),
            ["酷い騒音\n0"]
        )
    }

    // MARK: - removingTag

    func testRemovingSuffixedEntry() {
        XCTAssertEqual(
            FinderTagWriter.removingTag("Work", from: ["Work\n0", "Urgent\n0"]),
            ["Urgent\n0"]
        )
    }

    func testRemovingBareFormEntry() {
        XCTAssertEqual(
            FinderTagWriter.removingTag("Work", from: ["Work", "Urgent"]),
            ["Urgent"]
        )
    }

    func testRemovingNonexistentTagIsNoOp() {
        let existing = ["Work\n0"]
        XCTAssertEqual(FinderTagWriter.removingTag("Personal", from: existing), existing)
    }

    func testRemovingLastTagYieldsEmptyArray() {
        XCTAssertEqual(FinderTagWriter.removingTag("Work", from: ["Work\n0"]), [])
    }

    func testRemovingDoesNotTouchOtherColoredEntries() {
        XCTAssertEqual(
            FinderTagWriter.removingTag("Plain", from: ["Red\n6", "Plain\n0", "Blue\n4"]),
            ["Red\n6", "Blue\n4"]
        )
    }

    // MARK: - I/O round trip (temp file)

    func testWriteAndReadBackRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tagwriter_test_\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: url) }

        try FinderTagWriter.writeRawEntries(["Work\n0", "Red\n6"], to: url)
        XCTAssertEqual(ExtendedAttributeReader.rawUserTagsPropertyList(at: url), ["Work\n0", "Red\n6"])

        // Empty array removes the attribute entirely.
        try FinderTagWriter.writeRawEntries([], to: url)
        XCTAssertNil(ExtendedAttributeReader.rawUserTagsPropertyList(at: url))

        // Removing when already absent must not throw.
        XCTAssertNoThrow(try FinderTagWriter.writeRawEntries([], to: url))
    }
}
