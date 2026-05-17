import XCTest
import CoreData
import Domain
@testable import Data

/// Entity ↔ Domain 변환(`toDomain` / `toEntity`)의 동작을 검증한다.
///
/// 매핑 누락은 사용자 데이터 손실로 이어지므로, 모든 필드와 관계가
/// 빠짐없이 옮겨지는지 직접 확인한다. 엔티티 생성·접근은 모두
/// background context 큐 위에서 수행한다.
final class MappingTests: XCTestCase {

    private var stack: CoreDataStack!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        context = stack.backgroundContext
    }

    override func tearDown() {
        context = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - MemoEntity → Memo

    func test_MemoEntity_변환시_모든_단일값_필드가_복사된다() {
        context.performAndWait {
            // given
            let entity = MemoEntity(context: context)
            entity.memoTitle = "제목"
            entity.memoText = "본문"
            entity.isFavorite = true
            entity.isInTrash = true

            // when
            let memo = entity.toDomain()

            // then
            XCTAssertEqual(memo.memoID, entity.memoID)
            XCTAssertEqual(memo.memoTitle, "제목")
            XCTAssertEqual(memo.memoText, "본문")
            XCTAssertTrue(memo.isFavorite)
            XCTAssertTrue(memo.isInTrash)
            XCTAssertEqual(memo.creationDate, entity.creationDate)
            XCTAssertEqual(memo.modificationDate, entity.modificationDate)
        }
    }

    func test_MemoEntity_변환시_카테고리_관계가_매핑된다() {
        context.performAndWait {
            // given
            let memoEntity = MemoEntity(context: context)
            let categoryEntity = CategoryEntity(context: context)
            categoryEntity.name = "업무"
            memoEntity.addToCategories(categoryEntity)

            // when
            let memo = memoEntity.toDomain()

            // then
            XCTAssertEqual(memo.categories.map(\.name), ["업무"])
        }
    }

    func test_MemoEntity_변환시_이미지_관계가_매핑된다() {
        context.performAndWait {
            // given
            let memoEntity = MemoEntity(context: context)
            let imageID = UUID()
            let imageEntity = ImageEntity(
                uuid: imageID,
                thumbnailUUID: UUID(),
                temporaryOrderIndex: 0,
                orderIndex: 0,
                isTemporaryAppended: false,
                fileExtension: "heic",
                memo: memoEntity,
                context: context
            )
            memoEntity.addToImages(imageEntity)

            // when
            let memo = memoEntity.toDomain()

            // then
            XCTAssertEqual(memo.images.map(\.id), [imageID])
        }
    }

    func test_관계가_없는_MemoEntity는_빈_집합으로_변환된다() {
        context.performAndWait {
            // given
            let entity = MemoEntity(context: context)

            // when
            let memo = entity.toDomain()

            // then
            XCTAssertTrue(memo.categories.isEmpty)
            XCTAssertTrue(memo.images.isEmpty)
        }
    }

    // MARK: - CategoryEntity → Category

    func test_CategoryEntity_변환시_이름과_날짜가_복사된다() {
        context.performAndWait {
            // given
            let entity = CategoryEntity(context: context)
            entity.name = "개인"

            // when
            let category = entity.toDomain()

            // then
            XCTAssertEqual(category.name, "개인")
            XCTAssertEqual(category.creationDate, entity.creationDate)
            XCTAssertEqual(category.modificationDate, entity.modificationDate)
        }
    }

    // MARK: - ImageEntity → MemoImageInfo

    func test_ImageEntity_변환시_소속_메모ID를_포함한_모든_필드가_복사된다() {
        context.performAndWait {
            // given
            let memoEntity = MemoEntity(context: context)
            let imageID = UUID()
            let thumbnailID = UUID()
            let entity = ImageEntity(
                uuid: imageID,
                thumbnailUUID: thumbnailID,
                temporaryOrderIndex: 3,
                orderIndex: 5,
                isTemporaryAppended: true,
                fileExtension: "jpeg",
                memo: memoEntity,
                context: context
            )

            // when
            let info = entity.toDomain()

            // then
            XCTAssertEqual(info.id, imageID)
            XCTAssertEqual(info.thumbnailID, thumbnailID)
            XCTAssertEqual(info.temporaryOrderIndex, 3)
            XCTAssertEqual(info.orderIndex, 5)
            XCTAssertTrue(info.isTemporaryAppended)
            XCTAssertEqual(info.fileExtension, "jpeg")
            XCTAssertEqual(info.memoID, memoEntity.memoID)
        }
    }

    // MARK: - Category → CategoryEntity

    func test_같은_이름의_엔티티가_없으면_새_CategoryEntity를_만든다() {
        context.performAndWait {
            // given: 컨텍스트에 같은 이름의 엔티티가 없음
            let category = Domain.Category(name: "신규", creationDate: .now, modificationDate: .now)

            // when
            let entity = category.toEntity(in: context)

            // then
            XCTAssertEqual(entity.name, "신규")
        }
    }

    func test_같은_이름의_엔티티가_있으면_기존_것을_재사용한다() {
        context.performAndWait {
            // given: 이미 "업무" CategoryEntity가 컨텍스트에 존재
            let existing = CategoryEntity(context: context)
            existing.name = "업무"
            try? context.save()

            // when: 같은 이름의 Domain 모델을 엔티티로 변환하면
            let category = Domain.Category(name: "업무", creationDate: .now, modificationDate: .now)
            let entity = category.toEntity(in: context)

            // then: 새로 만들지 않고 기존 엔티티를 그대로 돌려준다
            XCTAssertTrue(entity === existing)
        }
    }

    // MARK: - 양방향 관계

    func test_메모에_카테고리를_추가하면_카테고리도_그_메모를_가리킨다() {
        context.performAndWait {
            // given
            let memoEntity = MemoEntity(context: context)
            let categoryEntity = CategoryEntity(context: context)
            categoryEntity.name = "업무"

            // when: 메모 쪽에서만 카테고리를 연결해도
            memoEntity.addToCategories(categoryEntity)

            // then: 역방향(카테고리 → 메모)이 자동으로 함께 연결된다
            XCTAssertTrue(categoryEntity.memoSet.contains(memoEntity))
            XCTAssertEqual(categoryEntity.memoSet.count, 1)
        }
    }
}
