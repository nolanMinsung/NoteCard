import XCTest
import UIKit
@testable import Data

/// `ImageFileHandler`의 순수 함수와 파일 시스템 동작을 검증한다.
///
/// 썸네일 리사이즈와 명시적 URL을 받는 save/load/delete만 다룬다.
/// `getDirectory` / `getFileURL`은 실제 documentDirectory에 의존하므로,
/// base directory 주입이 가능해진 뒤 별도 작업에서 다룬다.
final class ImageFileHandlerTests: XCTestCase {

    // MARK: - 썸네일 리사이즈

    func test_최대_크기보다_큰_이미지는_썸네일에서_축소된다() throws {
        // given: 800x400 이미지, 최대 변 400
        let source = makeImage(size: CGSize(width: 800, height: 400))

        // when
        let thumbnail = try ImageFileHandler.createThumbnailImage(from: source, maxPixelSize: 400)

        // then: 긴 변이 400으로 줄고 종횡비(2:1)가 유지된다
        XCTAssertEqual(thumbnail.size.width, 400, accuracy: 0.5)
        XCTAssertEqual(thumbnail.size.height, 200, accuracy: 0.5)
    }

    func test_최대_크기보다_작은_이미지는_썸네일에서_크기가_유지된다() throws {
        // given: 최대 변보다 작은 이미지
        let source = makeImage(size: CGSize(width: 100, height: 80))

        // when
        let thumbnail = try ImageFileHandler.createThumbnailImage(from: source, maxPixelSize: 400)

        // then: 크기가 그대로 유지된다
        XCTAssertEqual(thumbnail.size.width, 100, accuracy: 0.5)
        XCTAssertEqual(thumbnail.size.height, 80, accuracy: 0.5)
    }

    func test_썸네일_Data는_다시_이미지로_디코딩된다() throws {
        // given
        let source = makeImage(size: CGSize(width: 600, height: 600))

        // when
        let data = try ImageFileHandler.createThumbnailData(from: source, maxPixelSize: 200)

        // then
        XCTAssertFalse(data.isEmpty)
        XCTAssertNotNil(UIImage(data: data))
    }

    // MARK: - 파일 시스템 작업

    func test_저장한_파일을_같은_경로에서_이미지로_불러올_수_있다() throws {
        // given
        let directory = try makeTemporaryDirectory()
        let id = UUID()
        let data = try ImageFileHandler.createThumbnailData(
            from: makeImage(size: CGSize(width: 50, height: 50))
        )

        // when: 저장한 뒤 같은 경로에서 로드하면
        try ImageFileHandler.save(data: data, to: directory, with: id, fileExtension: "jpeg")
        let fileURL = directory.appendingPathComponent(id.uuidString).appendingPathExtension("jpeg")
        let loaded = try ImageFileHandler.loadUIImage(from: fileURL)

        // then
        XCTAssertGreaterThan(loaded.size.width, 0)
    }

    func test_존재하지_않는_파일을_불러오면_에러를_던진다() {
        // given: 존재하지 않는 파일 경로
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpeg")

        // when / then
        XCTAssertThrowsError(try ImageFileHandler.loadUIImage(from: missingURL))
    }

    func test_저장된_파일을_삭제할_수_있다() throws {
        // given: 저장된 파일
        let directory = try makeTemporaryDirectory()
        let id = UUID()
        let data = try ImageFileHandler.createThumbnailData(
            from: makeImage(size: CGSize(width: 50, height: 50))
        )
        try ImageFileHandler.save(data: data, to: directory, with: id, fileExtension: "jpeg")
        let fileURL = directory.appendingPathComponent(id.uuidString).appendingPathExtension("jpeg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // when
        try ImageFileHandler.delete(at: fileURL)

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func test_존재하지_않는_파일을_삭제해도_에러를_던지지_않는다() {
        // given: 존재하지 않는 파일 경로
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpeg")

        // when / then: 없는 파일을 삭제해도 에러를 던지지 않는다
        XCTAssertNoThrow(try ImageFileHandler.delete(at: missingURL))
    }

    // MARK: - 헬퍼

    private func makeImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { rendererContext in
            UIColor.systemBlue.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }
}
