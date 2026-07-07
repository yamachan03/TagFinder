import XCTest
@testable import TagFinder

final class SavedSearchTests: XCTestCase {
    private func makeAdvanced() -> SavedSearch {
        SavedSearch(
            name: "仕事の緊急",
            mode: .advanced,
            matchMode: .and,
            selectedTags: [],
            outerMode: .or,
            groups: [
                SavedSearch.Group(mode: .and, terms: [
                    GroupTerm(name: "Work"),
                    GroupTerm(name: "Personal", negated: true),
                ]),
                SavedSearch.Group(mode: .or, terms: [
                    GroupTerm(name: "酷い騒音"),
                ]),
            ]
        )
    }

    func testCodableRoundTripPreservesGroupsAndNegation() throws {
        let original = makeAdvanced()
        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([SavedSearch].self, from: data)
        XCTAssertEqual(decoded, [original])
    }

    func testExpressionGroupsRebuildContentWithFreshIDs() {
        let saved = makeAdvanced()
        let rebuilt1 = saved.expressionGroups
        let rebuilt2 = saved.expressionGroups
        XCTAssertEqual(rebuilt1.map(\.terms), saved.groups.map(\.terms))
        XCTAssertEqual(rebuilt1.map(\.mode), saved.groups.map(\.mode))
        // Runtime UUIDs are freshly minted per rebuild.
        XCTAssertNotEqual(rebuilt1.map(\.id), rebuilt2.map(\.id))
    }

    func testAdvancedExpressionPreview() {
        XCTAssertEqual(
            makeAdvanced().expression?.displayString,
            "(Work AND NOT Personal) OR 酷い騒音"
        )
    }

    func testSimpleExpressionPreview() {
        let saved = SavedSearch(
            name: "s",
            mode: .simple,
            matchMode: .or,
            selectedTags: ["Urgent", "Work"],
            outerMode: .or,
            groups: []
        )
        XCTAssertEqual(saved.expression?.displayString, "Urgent OR Work")
    }

    func testEmptySavedSearchHasNilExpression() {
        let saved = SavedSearch(
            name: "empty",
            mode: .advanced,
            matchMode: .and,
            selectedTags: [],
            outerMode: .or,
            groups: []
        )
        XCTAssertNil(saved.expression)
    }
}
