import XCTest
@testable import Domain

final class DomainModelInitTests: XCTestCase {

    func test_category_initializer_setsAllProperties() {
        let now = Date()
        let later = now.addingTimeInterval(60)
        let id = UUID()
        let c = Category(id: id, name: "Work", creationDate: now, modificationDate: later)
        XCTAssertEqual(c.id, id)
        XCTAssertEqual(c.name, "Work")
        XCTAssertEqual(c.creationDate, now)
        XCTAssertEqual(c.modificationDate, later)
    }

    func test_category_comparable_byModificationDateThenCreation() {
        let now = Date()
        let earlier = now.addingTimeInterval(-60)
        let a = Category(id: UUID(), name: "A", creationDate: earlier, modificationDate: now)
        let b = Category(id: UUID(), name: "B", creationDate: now, modificationDate: now.addingTimeInterval(10))
        XCTAssertLessThan(a, b)
    }
}
