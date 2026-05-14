import XCTest
import CoreData
@testable import Data

/// Heavyweight Core Data 마이그레이션 회귀 테스트.
///
/// 사용자 fixture(.sqlite) 의존성이 있어 현재는 XCTSkip된 상태로 둠.
/// Tuist 마이그레이션 후 검증 절차:
/// 1. v2.1.x 빌드로 시뮬레이터에서 데이터 생성 (메모 N개, 카테고리, 이미지 포함)
/// 2. 시뮬레이터의 App 컨테이너에서 NoteCardCoreData.sqlite, -wal, -shm 3파일을
///    `Projects/Data/Tests/Fixtures/v3/` 아래로 복사
/// 3. 이 파일 상단의 `fixtureURL`을 활성화하고 `XCTSkip`을 제거한 뒤
///    `xcodebuild test -scheme NoteCard -only-testing:DataTests/MigrationTests`
///
/// 검증 의도: Data 모듈로 옮긴 후에도 Heavyweight Migration이 자동으로 작동하여
/// 기존 사용자 데이터가 손실 없이 새 모델로 변환되는지 확인.
final class MigrationTests: XCTestCase {

    func test_v3_sqlite_migrates_to_latest_without_data_loss() throws {
        throw XCTSkip("v3 fixture .sqlite 미확보 — 사용자가 시뮬레이터에서 추출 후 활성화.")

        // 활성화 예시 (fixture 확보 후):
        // let bundle = Bundle(for: type(of: self))
        // guard let fixtureURL = bundle.url(forResource: "v3_seed", withExtension: "sqlite") else {
        //     XCTFail("v3_seed.sqlite missing in test bundle")
        //     return
        // }
        // let tmpDir = FileManager.default.temporaryDirectory
        //     .appending(path: UUID().uuidString)
        // try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        // let dstURL = tmpDir.appending(path: "NoteCardCoreData.sqlite")
        // try FileManager.default.copyItem(at: fixtureURL, to: dstURL)
        //
        // let modelURL = Bundle(for: CoreDataStack.self)
        //     .url(forResource: "NoteCardCoreData", withExtension: "momd")!
        // let model = NSManagedObjectModel(contentsOf: modelURL)!
        // let container = NSPersistentContainer(name: "NoteCardCoreData", managedObjectModel: model)
        // let desc = NSPersistentStoreDescription(url: dstURL)
        // desc.shouldMigrateStoreAutomatically = true
        // desc.shouldInferMappingModelAutomatically = true
        // container.persistentStoreDescriptions = [desc]
        // let exp = expectation(description: "load")
        // container.loadPersistentStores { _, error in
        //     XCTAssertNil(error)
        //     exp.fulfill()
        // }
        // wait(for: [exp], timeout: 10)
        // let request = MemoEntity.fetchRequest()
        // let fetched = try container.viewContext.fetch(request)
        // XCTAssertGreaterThan(fetched.count, 0, "Migration should preserve memo entities")
    }
}
