//
//  ImageUploadProgressStore.swift
//  NoteCard
//

import Combine
import Domain
import Foundation
import SyncInterface

/// 익명 → Firestore 마이그레이션에서 이미지 바이너리(Storage) 업로드의 per-image 완료 여부를
/// UserDefaults 에 영속화하고, 진행 상황(`UploadProgressSnapshot`)을 Combine publisher 로 노출한다.
///
/// 한 사용자 안에서 원본·썸네일을 **별도로** 추적해, 한 쪽만 올라간 상태에서 끊겨도 복원 시
/// 남은 쪽만 다시 시도할 수 있게 한다.
///
/// - 영속 key: `sync.imageBinaryUpload.<userID>` 한 개. 값은 `Set<String>` 직렬화 (`[String]`).
/// - 토큰 형식: `"original:<imageInfo.id>"`, `"thumbnail:<imageInfo.thumbnailID>"`.
/// - 진행 상황은 `setProgressTarget(_:)` 으로 알려준 이미지 목록을 기준으로 계산. mark / clear
///   시점마다 자동 emit. 전부 완료됐거나 target 이 비어 있으면 nil 을 emit 해 UI 가 표시를 숨김.
/// - 동시 호출 보호: 내부 NSLock. 모든 API 동기.
final class ImageUploadProgressStore: @unchecked Sendable {

    enum Variant: String, Sendable {
        case original
        case thumbnail
    }

    private let userID: String
    private let userDefaults: UserDefaults
    private let lock = NSLock()
    private var totalImageInfos: [MemoImageInfo] = []
    private let progressSubject = CurrentValueSubject<UploadProgressSnapshot?, Never>(nil)

    var progressPublisher: AnyPublisher<UploadProgressSnapshot?, Never> {
        progressSubject.eraseToAnyPublisher()
    }

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
        lock.withLock {
            var set = currentSet()
            set.insert(token(for: imageInfo, variant: variant))
            save(set)
        }
        recalculateAndEmit()
    }

    func isUploaded(imageInfo: MemoImageInfo, variant: Variant) -> Bool {
        lock.withLock {
            currentSet().contains(token(for: imageInfo, variant: variant))
        }
    }

    /// 주어진 이미지 전부의 원본·썸네일이 모두 마킹되어 있으면 true. 빈 배열은 true.
    func isAllUploaded(amongst infos: [MemoImageInfo]) -> Bool {
        lock.withLock {
            let set = currentSet()
            for info in infos {
                if !set.contains(token(for: info, variant: .original)) { return false }
                if !set.contains(token(for: info, variant: .thumbnail)) { return false }
            }
            return true
        }
    }

    /// 미완료 항목의 variant 합 — 원본/썸네일 각각 1 카운트.
    func pendingCount(amongst infos: [MemoImageInfo]) -> Int {
        lock.withLock {
            let set = currentSet()
            var count = 0
            for info in infos {
                if !set.contains(token(for: info, variant: .original)) { count += 1 }
                if !set.contains(token(for: info, variant: .thumbnail)) { count += 1 }
            }
            return count
        }
    }

    /// 마이그레이션 대상 이미지 목록을 알려줘 progress 계산의 기준으로 사용. 이후 mark 시점마다
    /// 자동으로 (completed, total) snapshot 을 emit. 전부 완료됐거나 infos 가 비면 nil 을 emit.
    func setProgressTarget(_ infos: [MemoImageInfo]) {
        lock.withLock {
            totalImageInfos = infos
        }
        recalculateAndEmit()
    }

    /// progress 표시를 명시적으로 끔 (sign-out 등). nil 을 emit.
    func clearProgressTarget() {
        lock.withLock {
            totalImageInfos = []
        }
        progressSubject.send(nil)
    }

    func clearAll() {
        lock.withLock {
            userDefaults.removeObject(forKey: storageKey)
        }
        recalculateAndEmit()
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

    private func recalculateAndEmit() {
        let (set, infos): (Set<String>, [MemoImageInfo]) = lock.withLock {
            (currentSet(), totalImageInfos)
        }
        guard !infos.isEmpty else {
            progressSubject.send(nil)
            return
        }
        var completed = 0
        for info in infos {
            if set.contains(token(for: info, variant: .original))
                && set.contains(token(for: info, variant: .thumbnail)) {
                completed += 1
            }
        }
        if completed >= infos.count {
            progressSubject.send(nil)
        } else {
            progressSubject.send(UploadProgressSnapshot(
                completedImageCount: completed,
                totalImageCount: infos.count
            ))
        }
    }
}
