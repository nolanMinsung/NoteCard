//
//  ImageUploadProgressStore.swift
//  NoteCard
//

import Domain
import Foundation

/// 익명 → Firestore 마이그레이션에서 이미지 바이너리(Storage) 업로드의 per-image 완료 여부를
/// UserDefaults 에 영속화한다.
///
/// 한 사용자 안에서 원본·썸네일을 **별도로** 추적해, 한 쪽만 올라간 상태에서 끊겨도 복원 시
/// 남은 쪽만 다시 시도할 수 있게 한다.
///
/// - 키: `sync.imageBinaryUpload.<userID>` 한 개. 값은 `Set<String>` 직렬화 (`[String]`).
/// - 토큰 형식: `"original:<imageInfo.id>"`, `"thumbnail:<imageInfo.thumbnailID>"`.
/// - 동시 호출 보호: 내부 NSLock. 모든 API 는 동기 — async 컨텍스트에서도 짧게 호출하고 빠짐.
final class ImageUploadProgressStore: @unchecked Sendable {

    enum Variant: String, Sendable {
        case original
        case thumbnail
    }

    private let userID: String
    private let userDefaults: UserDefaults
    private let lock = NSLock()

    init(userID: String, userDefaults: UserDefaults = .standard) {
        self.userID = userID
        self.userDefaults = userDefaults
    }

    static func storageKey(for userID: String) -> String {
        "sync.imageBinaryUpload.\(userID)"
    }

    private var storageKey: String { Self.storageKey(for: userID) }

    // MARK: - API

    func markUploaded(imageInfo: MemoImageInfo, variant: Variant) {
        lock.lock()
        defer { lock.unlock() }
        var set = currentSet()
        set.insert(token(for: imageInfo, variant: variant))
        save(set)
    }

    func isUploaded(imageInfo: MemoImageInfo, variant: Variant) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentSet().contains(token(for: imageInfo, variant: variant))
    }

    /// 주어진 이미지 전부의 원본·썸네일이 모두 마킹되어 있으면 true. 빈 배열은 true.
    func isAllUploaded(amongst infos: [MemoImageInfo]) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let set = currentSet()
        for info in infos {
            if !set.contains(token(for: info, variant: .original)) { return false }
            if !set.contains(token(for: info, variant: .thumbnail)) { return false }
        }
        return true
    }

    /// 미완료 항목의 variant 합 — 원본/썸네일 각각 1 카운트. UI 진행 표시용 (이번 PR 미사용).
    func pendingCount(amongst infos: [MemoImageInfo]) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let set = currentSet()
        var count = 0
        for info in infos {
            if !set.contains(token(for: info, variant: .original)) { count += 1 }
            if !set.contains(token(for: info, variant: .thumbnail)) { count += 1 }
        }
        return count
    }

    func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.removeObject(forKey: storageKey)
    }

    // MARK: - Internals

    private func token(for info: MemoImageInfo, variant: Variant) -> String {
        switch variant {
        case .original:
            return "\(Variant.original.rawValue):\(info.id.uuidString)"
        case .thumbnail:
            return "\(Variant.thumbnail.rawValue):\(info.thumbnailID.uuidString)"
        }
    }

    private func currentSet() -> Set<String> {
        guard let array = userDefaults.array(forKey: storageKey) as? [String] else { return [] }
        return Set(array)
    }

    private func save(_ set: Set<String>) {
        userDefaults.set(Array(set), forKey: storageKey)
    }
}
