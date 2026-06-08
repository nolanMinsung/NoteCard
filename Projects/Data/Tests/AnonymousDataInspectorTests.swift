import CoreData
import XCTest
import Domain
@testable import Data

/// `AnonymousDataInspector.snapshotCounts` 의 entity 별 카운트 정확성을 검증.
/// 매 테스트마다 inMemory stack 으로 격리.
final class AnonymousDataInspectorTests: XCTestCase {

    private var stack: CoreDataStack!
    private var memoRepository: MemoRepositoryImpl!
    private var categoryRepository: CategoryRepositoryImpl!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        memoRepository = MemoRepositoryImpl(stack: stack)
        categoryRepository = CategoryRepositoryImpl(stack: stack)
    }

    override func tearDown() {
        memoRepository = nil
        categoryRepository = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - 빈 stack

    func test_빈_stack_은_모든_카운트가_0() {
        // when
        let counts = AnonymousDataInspector.snapshotCounts(in: stack)

        // then
        XCTAssertEqual(counts.memoCount, 0)
        XCTAssertEqual(counts.trashedMemoCount, 0)
        XCTAssertEqual(counts.categoryCount, 0)
        XCTAssertEqual(counts.imageCount, 0)
    }

    // MARK: - 메모 / 휴지통 분리

    func test_활성_메모만_있으면_memoCount_만_증가() async throws {
        // given
        _ = try await memoRepository.createNewMemo()
        _ = try await memoRepository.createNewMemo()

        // when
        let counts = AnonymousDataInspector.snapshotCounts(in: stack)

        // then
        XCTAssertEqual(counts.memoCount, 2)
        XCTAssertEqual(counts.trashedMemoCount, 0)
    }

    func test_휴지통으로_옮긴_메모는_trashedMemoCount_에_잡힌다() async throws {
        // given: 3 장 중 1 장 휴지통으로
        let memo1 = try await memoRepository.createNewMemo()
        _ = try await memoRepository.createNewMemo()
        _ = try await memoRepository.createNewMemo()
        try await memoRepository.moveToTrash(memo1)

        // when
        let counts = AnonymousDataInspector.snapshotCounts(in: stack)

        // then
        XCTAssertEqual(counts.memoCount, 2)
        XCTAssertEqual(counts.trashedMemoCount, 1)
    }

    // MARK: - 카테고리

    func test_카테고리_생성_시_categoryCount_증가() async throws {
        // given
        try await categoryRepository.create(name: "업무")
        try await categoryRepository.create(name: "개인")

        // when
        let counts = AnonymousDataInspector.snapshotCounts(in: stack)

        // then
        XCTAssertEqual(counts.categoryCount, 2)
    }

    // MARK: - 이미지

    func test_이미지_entity_는_imageCount_에_잡힌다() async throws {
        // given: 메모 + 그 메모에 ImageEntity 직접 부착 (Picker 없이 raw entity 시드)
        let memo = try await memoRepository.createNewMemo()
        try seedImageEntities(memoID: memo.memoID, count: 5)

        // when
        let counts = AnonymousDataInspector.snapshotCounts(in: stack)

        // then
        XCTAssertEqual(counts.memoCount, 1)
        XCTAssertEqual(counts.imageCount, 5)
    }

    // MARK: - 헬퍼

    /// 메모에 raw ImageEntity 를 N 개 부착. PHPicker 흐름을 거치지 않고도 카운트 검증 가능.
    private func seedImageEntities(memoID: UUID, count: Int) throws {
        let context = stack.backgroundContext
        var thrown: Error?
        context.performAndWait {
            let request = MemoEntity.fetchRequest()
            request.predicate = NSPredicate(format: "memoID == %@", memoID as CVarArg)
            do {
                guard let memoEntity = try context.fetch(request).first else {
                    thrown = NSError(domain: "test", code: 1)
                    return
                }
                for index in 0..<count {
                    let image = ImageEntity(context: context)
                    image.uuid = UUID()
                    image.thumbnailUUID = UUID()
                    image.orderIndex = Int64(index)
                    image.temporaryOrderIndex = Int64(index)
                    image.isTemporaryAppended = false
                    image.isTemporaryDeleted = false
                    image.fileExtension = "jpeg"
                    image.memo = memoEntity
                }
                try context.save()
            } catch {
                thrown = error
            }
        }
        if let thrown { throw thrown }
    }
}
