import XCTest
@testable import Domain

final class DomainModelInitTests: XCTestCase {

    func test_category_initializer_setsAllProperties() {
        let now = Date()
        let later = now.addingTimeInterval(60)
        let c = Category(name: "Work", creationDate: now, modificationDate: later)
        XCTAssertEqual(c.name, "Work")
        XCTAssertEqual(c.creationDate, now)
        XCTAssertEqual(c.modificationDate, later)
    }

    func test_category_comparable_byModificationDateThenCreation() {
        let now = Date()
        let earlier = now.addingTimeInterval(-60)
        let a = Category(name: "A", creationDate: earlier, modificationDate: now)
        let b = Category(name: "B", creationDate: now, modificationDate: now.addingTimeInterval(10))
        XCTAssertLessThan(a, b)
    }
}
