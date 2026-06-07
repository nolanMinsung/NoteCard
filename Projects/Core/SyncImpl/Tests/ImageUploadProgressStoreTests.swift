import XCTest
import Domain
@testable import SyncImpl

/// `ImageUploadProgressStore` 의 mark·조회·영속화·격리 동작을 검증.
/// 각 테스트는 UserDefaults suite 를 새로 만들어 다른 테스트와 격리.
final class ImageUploadProgressStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private let userID = "test-user"

    override func setUp() {
        super.setUp()
        suiteName = "ImageUploadProgressStoreTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - 헬퍼

    private func makeSUT() -> ImageUploadProgressStore {
        ImageUploadProgressStore(userID: userID, userDefaults: userDefaults)
    }

    private func makeImageInfo() -> MemoImageInfo {
        MemoImageInfo(
            id: UUID(),
            thumbnailID: UUID(),
            temporaryOrderIndex: 0,
            orderIndex: 0,
            memoID: UUID(),
            isTemporaryDeleted: false,
            isTemporaryAppended: false,
            fileExtension: "jpeg"
        )
    }

    // MARK: - mark / isUploaded

    func test_초기상태에서_isUploaded_는_false_를_반환한다() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()

        // then
        XCTAssertFalse(sut.isUploaded(imageInfo: info, variant: .original))
        XCTAssertFalse(sut.isUploaded(imageInfo: info, variant: .thumbnail))
    }

    func test_mark_한_뒤_isUploaded_는_true_를_반환한다() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()

        // when
        sut.markUploaded(imageInfo: info, variant: .original)

        // then
        XCTAssertTrue(sut.isUploaded(imageInfo: info, variant: .original))
    }

    func test_같은_mark_를_여러번_호출해도_상태가_바뀌지_않는다() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()

        // when
        sut.markUploaded(imageInfo: info, variant: .original)
        sut.markUploaded(imageInfo: info, variant: .original)
        sut.markUploaded(imageInfo: info, variant: .original)

        // then
        XCTAssertTrue(sut.isUploaded(imageInfo: info, variant: .original))
        XCTAssertEqual(sut.pendingCount(amongst: [info]), 1) // 썸네일만 남음
    }

    func test_원본과_썸네일은_독립적으로_추적된다() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()

        // when
        sut.markUploaded(imageInfo: info, variant: .original)

        // then
        XCTAssertTrue(sut.isUploaded(imageInfo: info, variant: .original))
        XCTAssertFalse(sut.isUploaded(imageInfo: info, variant: .thumbnail))
    }

    func test_다른_이미지의_mark_는_서로_영향을_주지_않는다() {
        // given
        let sut = makeSUT()
        let infoA = makeImageInfo()
        let infoB = makeImageInfo()

        // when
        sut.markUploaded(imageInfo: infoA, variant: .original)

        // then
        XCTAssertTrue(sut.isUploaded(imageInfo: infoA, variant: .original))
        XCTAssertFalse(sut.isUploaded(imageInfo: infoB, variant: .original))
    }

    // MARK: - 영속화

    func test_새_인스턴스에서도_이전_mark_가_그대로_조회된다() {
        // given
        let info = makeImageInfo()
        let firstSUT = makeSUT()

        // when
        firstSUT.markUploaded(imageInfo: info, variant: .original)
        firstSUT.markUploaded(imageInfo: info, variant: .thumbnail)
        let secondSUT = makeSUT()

        // then
        XCTAssertTrue(secondSUT.isUploaded(imageInfo: info, variant: .original))
        XCTAssertTrue(secondSUT.isUploaded(imageInfo: info, variant: .thumbnail))
    }

    // MARK: - isAllUploaded

    func test_isAllUploaded_빈_배열은_true() {
        // given
        let sut = makeSUT()

        // then
        XCTAssertTrue(sut.isAllUploaded(amongst: []))
    }

    func test_isAllUploaded_원본과_썸네일_모두_mark_되어야_true() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()

        // when: 원본만 mark
        sut.markUploaded(imageInfo: info, variant: .original)

        // then: 썸네일이 남아 false
        XCTAssertFalse(sut.isAllUploaded(amongst: [info]))

        // when: 썸네일도 mark
        sut.markUploaded(imageInfo: info, variant: .thumbnail)

        // then: 둘 다 끝나 true
        XCTAssertTrue(sut.isAllUploaded(amongst: [info]))
    }

    func test_isAllUploaded_여러장_중_한장이라도_미완이면_false() {
        // given
        let sut = makeSUT()
        let infoA = makeImageInfo()
        let infoB = makeImageInfo()

        // when: infoA 는 둘 다 mark, infoB 는 원본만 mark
        sut.markUploaded(imageInfo: infoA, variant: .original)
        sut.markUploaded(imageInfo: infoA, variant: .thumbnail)
        sut.markUploaded(imageInfo: infoB, variant: .original)

        // then
        XCTAssertFalse(sut.isAllUploaded(amongst: [infoA, infoB]))
    }

    // MARK: - pendingCount

    func test_pendingCount_는_미완료_variant_의_합이다() {
        // given
        let sut = makeSUT()
        let infoA = makeImageInfo()
        let infoB = makeImageInfo()

        // then: 아무것도 mark 안 됐을 때 두 장 × 두 variant = 4
        XCTAssertEqual(sut.pendingCount(amongst: [infoA, infoB]), 4)

        // when: infoA 원본만 mark
        sut.markUploaded(imageInfo: infoA, variant: .original)

        // then
        XCTAssertEqual(sut.pendingCount(amongst: [infoA, infoB]), 3)

        // when: 나머지도 모두 mark
        sut.markUploaded(imageInfo: infoA, variant: .thumbnail)
        sut.markUploaded(imageInfo: infoB, variant: .original)
        sut.markUploaded(imageInfo: infoB, variant: .thumbnail)

        // then
        XCTAssertEqual(sut.pendingCount(amongst: [infoA, infoB]), 0)
    }

    // MARK: - clearAll

    func test_clearAll_후에는_모든_mark_가_사라진다() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()
        sut.markUploaded(imageInfo: info, variant: .original)
        sut.markUploaded(imageInfo: info, variant: .thumbnail)

        // when
        sut.clearAll()

        // then
        XCTAssertFalse(sut.isUploaded(imageInfo: info, variant: .original))
        XCTAssertFalse(sut.isUploaded(imageInfo: info, variant: .thumbnail))
    }

    // MARK: - 사용자 격리

    func test_다른_userID_의_store_는_상태가_분리된다() {
        // given
        let info = makeImageInfo()
        let sutA = ImageUploadProgressStore(userID: "user-A", userDefaults: userDefaults)
        let sutB = ImageUploadProgressStore(userID: "user-B", userDefaults: userDefaults)

        // when
        sutA.markUploaded(imageInfo: info, variant: .original)

        // then
        XCTAssertTrue(sutA.isUploaded(imageInfo: info, variant: .original))
        XCTAssertFalse(sutB.isUploaded(imageInfo: info, variant: .original))
    }
}
