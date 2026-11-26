import XCTest
@testable import DinkyCalCore

final class TipsTests: XCTestCase {
    func test_productIDsInDisplayOrder() {
        XCTAssertEqual(TipCatalog.productIDs, [
            "com.joshtronic.dinkycal.tip.small",
            "com.joshtronic.dinkycal.tip.medium",
            "com.joshtronic.dinkycal.tip.large",
        ])
    }

    func test_orderedSortsByCatalogAndDropsUnknown() {
        let shuffled = ["com.joshtronic.dinkycal.tip.large", "com.example.other",
                        "com.joshtronic.dinkycal.tip.small", "com.joshtronic.dinkycal.tip.medium"]
        XCTAssertEqual(TipCatalog.ordered(shuffled, id: { $0 }), TipCatalog.productIDs)
    }
}
