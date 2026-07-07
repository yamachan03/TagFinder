import XCTest
@testable import TagFinder

/// True end-to-end matching can only be verified against the live Spotlight
/// index (checked manually with mdfind against the 5-file fixture); these tests
/// verify the part under this app's control: the exact mdfind-syntax query
/// string and header display string each expression produces.
final class TagExpressionTests: XCTestCase {
    // MARK: - Leaves and escaping

    func testTagLeafQuery() {
        XCTAssertEqual(
            TagExpression.tag("Work").queryString,
            "kMDItemUserTags == 'Work'"
        )
    }

    func testQuoteAndBackslashInTagNameAreEscaped() {
        XCTAssertEqual(
            TagExpression.tag("back\\slash'quote").queryString,
            "kMDItemUserTags == 'back\\\\slash\\'quote'"
        )
    }

    func testUnicodeTagNamePassesThrough() {
        XCTAssertEqual(
            TagExpression.tag("酷い騒音").queryString,
            "kMDItemUserTags == '酷い騒音'"
        )
    }

    // MARK: - Flat compounds (simple mode shapes)

    func testFlatAnd() {
        let expr = TagExpression.and([.tag("Work"), .tag("Urgent")])
        XCTAssertEqual(expr.queryString, "kMDItemUserTags == 'Work' && kMDItemUserTags == 'Urgent'")
        XCTAssertEqual(expr.displayString, "Work AND Urgent")
    }

    func testFlatOr() {
        let expr = TagExpression.or([.tag("Work"), .tag("Urgent")])
        XCTAssertEqual(expr.queryString, "kMDItemUserTags == 'Work' || kMDItemUserTags == 'Urgent'")
        XCTAssertEqual(expr.displayString, "Work OR Urgent")
    }

    // MARK: - Nesting (advanced mode shapes)

    func testOrOfAndGroupsParenthesizesEachGroup() {
        let expr = TagExpression.or([
            .and([.tag("A"), .tag("B")]),
            .and([.tag("C"), .tag("D")]),
            .tag("E"),
        ])
        XCTAssertEqual(
            expr.queryString,
            "(kMDItemUserTags == 'A' && kMDItemUserTags == 'B') || (kMDItemUserTags == 'C' && kMDItemUserTags == 'D') || kMDItemUserTags == 'E'"
        )
        XCTAssertEqual(expr.displayString, "(A AND B) OR (C AND D) OR E")
    }

    func testAndOfOrGroups() {
        let expr = TagExpression.and([
            .or([.tag("A"), .tag("B")]),
            .tag("C"),
        ])
        XCTAssertEqual(
            expr.queryString,
            "(kMDItemUserTags == 'A' || kMDItemUserTags == 'B') && kMDItemUserTags == 'C'"
        )
        XCTAssertEqual(expr.displayString, "(A OR B) AND C")
    }

    // MARK: - Collapsing and empty handling

    func testSingleChildCompoundCollapsesWithoutParens() {
        let expr = TagExpression.or([.and([.tag("A")])])
        XCTAssertEqual(expr.queryString, "kMDItemUserTags == 'A'")
        XCTAssertEqual(expr.displayString, "A")
    }

    func testEmptyCompoundYieldsNil() {
        XCTAssertNil(TagExpression.and([]).queryString)
        XCTAssertNil(TagExpression.or([]).queryString)
        XCTAssertNil(TagExpression.or([.and([]), .and([])]).queryString)
    }

    func testEmptyGroupsAreSkippedInsideCompound() {
        let expr = TagExpression.or([
            .and([]),
            .and([.tag("A"), .tag("B")]),
            .and([]),
        ])
        XCTAssertEqual(expr.queryString, "kMDItemUserTags == 'A' && kMDItemUserTags == 'B'")
        XCTAssertEqual(expr.displayString, "A AND B")
    }

    // MARK: - ExpressionGroup mapping

    func testExpressionGroupProducesFlatCompound() {
        var group = ExpressionGroup()
        group.tags = ["A", "B"]
        group.mode = .or
        XCTAssertEqual(group.expression, .or([.tag("A"), .tag("B")]))
    }

    func testEmptyExpressionGroupProducesNil() {
        XCTAssertNil(ExpressionGroup().expression)
    }

    // MARK: - Codable round trip (future saved searches)

    func testCodableRoundTrip() throws {
        let expr = TagExpression.or([
            .and([.tag("Work"), .tag("Urgent")]),
            .tag("酷い騒音"),
        ])
        let data = try JSONEncoder().encode(expr)
        let decoded = try JSONDecoder().decode(TagExpression.self, from: data)
        XCTAssertEqual(decoded, expr)
    }
}
