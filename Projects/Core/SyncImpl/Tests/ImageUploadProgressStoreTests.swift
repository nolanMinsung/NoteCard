import Combine
import XCTest
import Domain
import SyncInterface
@testable import SyncImpl

/// `ImageUploadProgressStore` 의 mark·조회·영속화·격리 + 진행상황 publisher 동작을 검증.
/// 각 테스트는 UserDefaults suite 를 새로 만들어 다른 테스트와 격리.
final class ImageUploadProgressStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var cancellables: Set<AnyCancellable> = []
    private let userID = "test-user"

    override func setUp() {
        super.setUp()
        suiteName = "ImageUploadProgressStoreTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        cancellables.removeAll()
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

    // MARK: - progressPublisher

    /// CurrentValueSubject 라 구독 시점에 현재값이 즉시 emit. 마지막 emit 값을 캡처해 반환.
    private func captureProgress(of sut: ImageUploadProgressStore) -> () -> UploadProgressSnapshot? {
        var lastEmitted: UploadProgressSnapshot?
        sut.progressPublisher
            .sink { lastEmitted = $0 }
            .store(in: &cancellables)
        return { lastEmitted }
    }

    func test_progressPublisher_초기값은_nil() {
        // given
        let sut = makeSUT()

        // when
        let progress = captureProgress(of: sut)

        // then
        XCTAssertNil(progress())
    }

    func test_setProgressTarget_빈_배열이면_nil_을_emit() {
        // given
        let sut = makeSUT()
        let progress = captureProgress(of: sut)

        // when
        sut.setProgressTarget([])

        // then
        XCTAssertNil(progress())
    }

    func test_setProgressTarget_후_아무것도_mark_안되어있으면_completed_0_을_emit() {
        // given
        let sut = makeSUT()
        let infoA = makeImageInfo()
        let infoB = makeImageInfo()
        let progress = captureProgress(of: sut)

        // when
        sut.setProgressTarget([infoA, infoB])

        // then
        XCTAssertEqual(progress(), UploadProgressSnapshot(completedImageCount: 0, totalImageCount: 2))
    }

    func test_원본만_mark_하면_completed_가_증가하지_않는다() {
        // given: target 2 장
        let sut = makeSUT()
        let infoA = makeImageInfo()
        let infoB = makeImageInfo()
        sut.setProgressTarget([infoA, infoB])
        let progress = captureProgress(of: sut)

        // when: infoA 원본만 mark
        sut.markUploaded(imageInfo: infoA, variant: .original)

        // then: 썸네일 미완 → 한 장도 완료된 게 없음
        XCTAssertEqual(progress(), UploadProgressSnapshot(completedImageCount: 0, totalImageCount: 2))
    }

    func test_한_이미지의_원본과_썸네일_둘다_mark_되어야_completed_가_증가한다() {
        // given
        let sut = makeSUT()
        let infoA = makeImageInfo()
        let infoB = makeImageInfo()
        sut.setProgressTarget([infoA, infoB])
        let progress = captureProgress(of: sut)

        // when
        sut.markUploaded(imageInfo: infoA, variant: .original)
        sut.markUploaded(imageInfo: infoA, variant: .thumbnail)

        // then
        XCTAssertEqual(progress(), UploadProgressSnapshot(completedImageCount: 1, totalImageCount: 2))
    }

    func test_모든_이미지가_완료되면_nil_을_emit() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()
        sut.setProgressTarget([info])
        let progress = captureProgress(of: sut)

        // when
        sut.markUploaded(imageInfo: info, variant: .original)
        sut.markUploaded(imageInfo: info, variant: .thumbnail)

        // then: 완료 시 hide 의미로 nil
        XCTAssertNil(progress())
    }

    func test_clearProgressTarget_후에는_nil_을_emit() {
        // given
        let sut = makeSUT()
        let info = makeImageInfo()
        sut.setProgressTarget([info])
        let progress = captureProgress(of: sut)
        XCTAssertNotNil(progress())

        // when
        sut.clearProgressTarget()

        // then
        XCTAssertNil(progress())
    }

    func test_setProgressTarget_재호출_시_새_target_기준으로_재계산() {
        // given: 첫 target 1장 + 그 장 완료
        let sut = makeSUT()
        let infoA = makeImageInfo()
        sut.setProgressTarget([infoA])
        sut.markUploaded(imageInfo: infoA, variant: .original)
        sut.markUploaded(imageInfo: infoA, variant: .thumbnail)
        let progress = captureProgress(of: sut)
        XCTAssertNil(progress()) // 첫 target 기준 완료

        // when: 새 target 으로 교체 (infoB 추가)
        let infoB = makeImageInfo()
        sut.setProgressTarget([infoA, infoB])

        // then: infoB 미완 → 1 / 2
        XCTAssertEqual(progress(), UploadProgressSnapshot(completedImageCount: 1, totalImageCount: 2))
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
