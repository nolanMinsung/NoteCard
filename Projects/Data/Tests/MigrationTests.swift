import XCTest
import CoreData
@testable import Data

/// Core Data 마이그레이션 회귀 테스트.
///
/// 옛 모델(`NoteCardCoreData` v1)로 store를 만들어 합성 데이터를 채운 뒤,
/// 현재 모델로 자동 마이그레이션하며 다시 열어 데이터가 보존되는지 검증한다.
///
/// 별도 fixture 파일을 커밋하지 않고 v1 `.mom`을 코드로 로드해 store를
/// 생성하므로, 실제 사용자 데이터가 저장소에 들어갈 일이 없고, 모델이
/// 바뀌어 마이그레이션이 깨지면 CI가 자동으로 잡아낸다.
///
/// v1 → v2 변경 내역: `ImageEntity`에 `fileExtension`(String, 기본값 "jpeg")
/// 속성 추가. 속성 추가 + 기본값이라 lightweight migration으로 자동 추론된다.
final class MigrationTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
    }

    // MARK: - Tests

    func test_v1_store가_데이터_손실_없이_현재_모델로_마이그레이션된다() throws {
        // given: v1 모델로 시드한 store를 현재 모델로 마이그레이션해서 연다
        let context = try seedV1StoreAndMigrate().viewContext

        // then: 메모 / 카테고리 / 이미지 개수가 모두 보존된다
        XCTAssertEqual(try count(of: "MemoEntity", in: context), 3)
        XCTAssertEqual(try count(of: "CategoryEntity", in: context), 2)
        XCTAssertEqual(try count(of: "ImageEntity", in: context), 1)

        // and: 메모의 내용·상태·카테고리 연결이 그대로 유지된다
        let meeting = try XCTUnwrap(memo(titled: "회의 메모", in: context))
        XCTAssertEqual(meeting.value(forKey: "memoText") as? String, "3시 디자인 리뷰")
        XCTAssertEqual(meeting.value(forKey: "isFavorite") as? Bool, true)
        let categoryNames = (meeting.value(forKey: "categories") as? Set<NSManagedObject>)?
            .compactMap { $0.value(forKey: "name") as? String }
        XCTAssertEqual(categoryNames, ["업무"])

        // and: 휴지통 메모의 상태도 유지된다
        let trashed = try XCTUnwrap(memo(titled: "삭제된 메모", in: context))
        XCTAssertEqual(trashed.value(forKey: "isInTrash") as? Bool, true)
    }

    func test_마이그레이션시_v2에_추가된_ImageEntity_fileExtension에_기본값이_채워진다() throws {
        // given: v1에는 fileExtension 속성이 없는 ImageEntity를 시드 후 마이그레이션
        let context = try seedV1StoreAndMigrate().viewContext

        // when: v2에서 추가된 fileExtension 속성을 읽으면
        let image = try XCTUnwrap(
            context.fetch(NSFetchRequest<NSManagedObject>(entityName: "ImageEntity")).first
        )

        // then: 모델에 정의된 기본값 "jpeg"이 채워져 있다
        XCTAssertEqual(image.value(forKey: "fileExtension") as? String, "jpeg")
    }

    // MARK: - Seed & migrate

    /// v1 모델로 store를 만들어 합성 데이터를 채운 뒤, 현재 모델로 자동
    /// 마이그레이션하며 다시 열어 그 컨테이너를 돌려준다.
    private func seedV1StoreAndMigrate() throws -> NSPersistentContainer {
        let storeURL = tempDirectory.appendingPathComponent("NoteCardCoreData.sqlite")
        try seedV1Store(at: storeURL)
        return try openContainer(at: storeURL, with: try currentModel(), migrating: true)
    }

    private func seedV1Store(at storeURL: URL) throws {
        let container = try openContainer(at: storeURL, with: try v1Model(), migrating: false)
        let context = container.viewContext

        let work = insert("CategoryEntity", into: context, values: [
            "name": "업무", "creationDate": Date(), "modificationDate": Date(),
        ])
        insert("CategoryEntity", into: context, values: [
            "name": "개인", "creationDate": Date(), "modificationDate": Date(),
        ])

        let meeting = insert("MemoEntity", into: context, values: [
            "memoID": UUID(), "creationDate": Date(), "modificationDate": Date(),
            "memoTitle": "회의 메모", "memoText": "3시 디자인 리뷰",
            "isFavorite": true, "isInTrash": false,
        ])
        meeting.mutableSetValue(forKey: "categories").add(work)

        insert("MemoEntity", into: context, values: [
            "memoID": UUID(), "creationDate": Date(), "modificationDate": Date(),
            "memoTitle": "삭제된 메모", "memoText": "휴지통 본문",
            "isFavorite": false, "isInTrash": true, "deletedDate": Date(),
        ])
        insert("MemoEntity", into: context, values: [
            "memoID": UUID(), "creationDate": Date(), "modificationDate": Date(),
            "memoTitle": "일반 메모", "memoText": "본문3",
            "isFavorite": false, "isInTrash": false,
        ])

        let image = insert("ImageEntity", into: context, values: [
            "uuid": UUID(), "thumbnailUUID": UUID(),
            "orderIndex": Int64(0), "temporaryOrderIndex": Int64(0),
            "isTemporaryAppended": false, "isTemporaryDeleted": false,
        ])
        image.setValue(meeting, forKey: "memo")

        try context.save()

        // 같은 .sqlite 파일을 다음 컨테이너가 열 수 있도록 store를 분리한다.
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func insert(
        _ entityName: String,
        into context: NSManagedObjectContext,
        values: [String: Any]
    ) -> NSManagedObject {
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        for (key, value) in values {
            object.setValue(value, forKey: key)
        }
        return object
    }

    private func openContainer(
        at storeURL: URL,
        with model: NSManagedObjectModel,
        migrating: Bool
    ) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "NoteCardCoreData", managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = migrating
        description.shouldInferMappingModelAutomatically = migrating
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        return container
    }

    /// `NoteCardCoreData.momd` 안의 특정 버전 `.mom`을 로드한다.
    /// `momFileName`이 nil이면 `.momd` 자체를 로드해 현재 버전 모델을 얻는다.
    private func model(momFileName: String?) throws -> NSManagedObjectModel {
        let momdURL = try XCTUnwrap(
            DataResources.bundle.url(forResource: "NoteCardCoreData", withExtension: "momd"),
            "NoteCardCoreData.momd를 Data 리소스 번들에서 찾을 수 없음"
        )
        let modelURL = momFileName.map { momdURL.appendingPathComponent($0) } ?? momdURL
        return try XCTUnwrap(
            NSManagedObjectModel(contentsOf: modelURL),
            "모델 로드 실패: \(modelURL.lastPathComponent)"
        )
    }

    private func v1Model() throws -> NSManagedObjectModel {
        try model(momFileName: "NoteCardCoreData.mom")
    }

    private func currentModel() throws -> NSManagedObjectModel {
        try model(momFileName: nil)
    }

    private func count(of entityName: String, in context: NSManagedObjectContext) throws -> Int {
        try context.count(for: NSFetchRequest<NSManagedObject>(entityName: entityName))
    }

    private func memo(titled title: String, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MemoEntity")
        request.predicate = NSPredicate(format: "memoTitle == %@", title)
        return try context.fetch(request).first
    }
}
