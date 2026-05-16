import XCTest
import UIKit
import Domain
@testable import Data

/// `ImageRepositoryImpl`의 동작을 검증하는 통합 테스트.
///
/// `createImage`는 `PHPickerResult`를 인자로 받는데 이 타입은 공개 이니셜라이저가
/// 없어 단위 테스트에서 생성할 수 없으므로 제외한다. 나머지 메서드는 in-memory
/// CoreDataStack과(파일이 필요한 경우) 임시 파일로 검증한다.
final class ImageRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var memoRepository: MemoRepositoryImpl!
    private var sut: ImageRepositoryImpl!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        memoRepository = MemoRepositoryImpl(stack: stack)
        sut = ImageRepositoryImpl(stack: stack, memoRepository: memoRepository)
    }

    override func tearDown() {
        sut = nil
        memoRepository = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - 이미지 목록 조회

    func test_메모에_속한_모든_이미지가_조회된다() async throws {
        // given: 이미지 3개를 가진 메모
        let (memoID, imageIDs) = insertMemo(imageCount: 3)

        // when
        let infos = try await sut.getAllImageInfo(for: memoStub(id: memoID))

        // then
        XCTAssertEqual(Set(infos.map(\.id)), Set(imageIDs))
    }

    func test_이미지는_orderIndex_오름차순으로_반환된다() async throws {
        // given: orderIndex 0, 1, 2 순으로 삽입된 이미지들
        let (memoID, imageIDs) = insertMemo(imageCount: 3)

        // when
        let infos = try await sut.getAllImageInfo(for: memoStub(id: memoID))

        // then: orderIndex 오름차순으로 반환된다
        XCTAssertEqual(infos.map(\.id), imageIDs)
    }

    func test_다른_메모의_이미지는_조회되지_않는다() async throws {
        // given: 서로 다른 두 메모
        let (_, _) = insertMemo(imageCount: 2)
        let (memoB, imagesB) = insertMemo(imageCount: 1)

        // when
        let infos = try await sut.getAllImageInfo(for: memoStub(id: memoB))

        // then: 조회한 메모의 이미지만 반환
        XCTAssertEqual(infos.map(\.id), imagesB)
    }

    func test_이미지가_없는_메모는_빈_목록을_반환한다() async throws {
        // given
        let (memoID, _) = insertMemo(imageCount: 0)

        // when
        let infos = try await sut.getAllImageInfo(for: memoStub(id: memoID))

        // then
        XCTAssertTrue(infos.isEmpty)
    }

    // MARK: - 이미지 순서 변경

    func test_이미지의_orderIndex를_변경할_수_있다() async throws {
        // given: orderIndex 0인 이미지
        let (memoID, imageIDs) = insertMemo(imageCount: 2)
        let target = imageInfoStub(id: imageIDs[0], memoID: memoID, orderIndex: 0)

        // when: 인덱스를 5로 변경
        try await sut.updateImageIndex(target, newIndex: 5)

        // then
        let infos = try await sut.getAllImageInfo(for: memoStub(id: memoID))
        let updated = infos.first { $0.id == imageIDs[0] }
        XCTAssertEqual(updated?.orderIndex, 5)
    }

    func test_존재하지_않는_이미지의_인덱스_변경시_에러를_던진다() async throws {
        // given: 저장소에 없는 이미지
        let ghost = imageInfoStub(id: UUID(), memoID: UUID(), orderIndex: 0)

        // when / then
        do {
            try await sut.updateImageIndex(ghost, newIndex: 1)
            XCTFail("존재하지 않는 이미지에 대해 에러를 던져야 한다")
        } catch {
            // 에러 발생 — 통과
        }
    }

    // MARK: - 이미지 삭제

    func test_이미지_삭제시_레코드와_파일이_모두_제거된다() async throws {
        // given: 이미지 1개 + 원본/썸네일 파일을 실제로 디스크에 생성
        let memoID = UUID()
        let imageID = UUID()
        let thumbnailID = UUID()
        insertMemo(memoID: memoID, imageSpecs: [(orderIndex: 0, id: imageID, thumbID: thumbnailID)])

        let directory = try ImageFileHandler.getDirectory(for: memoID)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let originalURL = fileURL(in: directory, id: imageID)
        let thumbnailURL = fileURL(in: directory, id: thumbnailID)
        let imageData = try ImageFileHandler.createThumbnailData(from: makeImage())
        try imageData.write(to: originalURL)
        try imageData.write(to: thumbnailURL)

        let info = imageInfoStub(id: imageID, thumbnailID: thumbnailID, memoID: memoID, orderIndex: 0)

        // when
        try await sut.deleteImage(info)

        // then: 파일과 Core Data 레코드가 모두 사라진다
        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: thumbnailURL.path))
        let remaining = try await sut.getAllImageInfo(for: memoStub(id: memoID))
        XCTAssertTrue(remaining.isEmpty)
    }

    // MARK: - 헬퍼

    private func insertMemo(imageCount: Int) -> (memoID: UUID, imageIDs: [UUID]) {
        let imageIDs = (0..<imageCount).map { _ in UUID() }
        let specs = imageIDs.enumerated().map {
            (orderIndex: $0.offset, id: $0.element, thumbID: UUID())
        }
        let memoID = UUID()
        insertMemo(memoID: memoID, imageSpecs: specs)
        return (memoID, imageIDs)
    }

    private func insertMemo(
        memoID: UUID,
        imageSpecs: [(orderIndex: Int, id: UUID, thumbID: UUID)]
    ) {
        let context = stack.backgroundContext
        context.performAndWait {
            let memoEntity = MemoEntity(context: context)
            memoEntity.memoID = memoID
            for spec in imageSpecs {
                _ = ImageEntity(
                    uuid: spec.id,
                    thumbnailUUID: spec.thumbID,
                    temporaryOrderIndex: Int64(spec.orderIndex),
                    orderIndex: Int64(spec.orderIndex),
                    isTemporaryAppended: false,
                    fileExtension: "jpeg",
                    memo: memoEntity,
                    context: context
                )
            }
            try? context.save()
        }
    }

    /// Repository는 `Memo`에서 `memoID`만 사용하므로 나머지 필드는 더미로 채운다.
    private func memoStub(id: UUID) -> Memo {
        Memo(
            memoID: id, creationDate: .now, modificationDate: .now, deletedDate: nil,
            isFavorite: false, isInTrash: false, memoText: "", memoTitle: "",
            categories: [], images: []
        )
    }

    private func imageInfoStub(
        id: UUID,
        thumbnailID: UUID = UUID(),
        memoID: UUID,
        orderIndex: Int
    ) -> MemoImageInfo {
        MemoImageInfo(
            id: id, thumbnailID: thumbnailID,
            temporaryOrderIndex: orderIndex, orderIndex: orderIndex,
            memoID: memoID, isTemporaryDeleted: false, isTemporaryAppended: false,
            fileExtension: "jpeg"
        )
    }

    private func fileURL(in directory: URL, id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString).appendingPathExtension("jpeg")
    }

    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30))
        return renderer.image { rendererContext in
            UIColor.systemBlue.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: 30, height: 30))
        }
    }
}
