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

final class MemoUpdateTypeTests: XCTestCase {

    func test_memoIDs는_각_케이스의_대상_메모ID를_반환한다() {
        let a = UUID()
        let b = UUID()

        XCTAssertEqual(MemoUpdateType.create(memoIDs: [a]).memoIDs, [a])
        XCTAssertEqual(MemoUpdateType.trash(memoIDs: [a, b]).memoIDs, [a, b])
        XCTAssertEqual(MemoUpdateType.delete(memoIDs: [a]).memoIDs, [a])
        XCTAssertEqual(MemoUpdateType.restore(memoIDs: [b]).memoIDs, [b])
    }

    func test_update_케이스의_memoIDs는_연관된_attribute의_memoIDs를_반환한다() {
        let a = UUID()
        let b = UUID()

        XCTAssertEqual(MemoUpdateType.update(content: .titleText(memoIDs: [a])).memoIDs, [a])
        XCTAssertEqual(MemoUpdateType.update(content: .favorite(memoIDs: [a, b])).memoIDs, [a, b])
        XCTAssertEqual(MemoUpdateType.update(content: .category(memoIDs: [b])).memoIDs, [b])
    }
}

final class CategoryUpdateTypeTests: XCTestCase {

    func test_categoryIDs는_각_케이스의_대상_카테고리ID를_반환한다() {
        let a = UUID()
        let b = UUID()

        XCTAssertEqual(CategoryUpdateType.create(categoryIDs: [a]).categoryIDs, [a])
        XCTAssertEqual(CategoryUpdateType.delete(categoryIDs: [a, b]).categoryIDs, [a, b])
        XCTAssertEqual(CategoryUpdateType.update(content: .name(categoryIDs: [a])).categoryIDs, [a])
        XCTAssertEqual(CategoryUpdateType.update(content: .modificationDate(categoryIDs: [b])).categoryIDs, [b])
    }
}
