//
//  ImageUploadProgressStore.swift
//  NoteCard
//

import Combine
import Domain
import Foundation
import SyncInterface

/// 익명 → Firestore 마이그레이션에서 이미지 바이너리(Storage) 업로드의 per-image 완료 여부와
/// 마이그레이션 대상 이미지 목록을 UserDefaults 에 영속화하고, 진행 상황
/// (`UploadProgressSnapshot`)을 Combine publisher 로 노출한다.
///
/// 한 사용자 안에서 원본·썸네일을 **별도로** 추적해, 한 쪽만 올라간 상태에서 끊겨도 복원 시
/// 남은 쪽만 다시 시도할 수 있게 한다.
///
/// - 완료 마킹 key: `sync.imageBinaryUpload.<userID>` — 값은 `Set<String>` 직렬화 (`[String]`).
///   토큰 형식: `"original:<imageInfo.id>"`, `"thumbnail:<imageInfo.thumbnailID>"`.
/// - 마이그레이션 대상 key: `sync.imageMigrationTarget.<userID>` — 값은 JSON `[MemoImageInfo]`.
///   `setProgressTarget(_:)` 시 영속화되고, 모든 항목이 완료되면 자동으로 삭제된다 (재진입 시
///   "이미 끝남"으로 해석할 수 있도록).
/// - 진행 상황은 mark / setProgressTarget 시점마다 자동 재계산해 emit. 완료됐거나 target 이
///   비어 있으면 nil 을 emit 해 UI 가 표시를 숨김.
/// - 동시 호출 보호: 내부 NSLock. 모든 API 동기.
final class ImageUploadProgressStore: @unchecked Sendable {

    enum Variant: String, Sendable {
        case original
        case thumbnail
    }

    private let userID: String
    private let userDefaults: UserDefaults
    private let lock = NSLock()
    private var totalImageInfos: [MemoImageInfo]
    private let progressSubject = CurrentValueSubject<UploadProgressSnapshot?, Never>(nil)

    var progressPublisher: AnyPublisher<UploadProgressSnapshot?, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    init(userID: String, userDefaults: UserDefaults = .standard) {
        self.userID = userID
        self.userDefaults = userDefaults
        self.totalImageInfos = Self.loadTarget(userID: userID, userDefaults: userDefaults)
    }

    static func storageKey(for userID: String) -> String {
        "sync.imageBinaryUpload.\(userID)"
    }

    static func targetStorageKey(for userID: String) -> String {
        "sync.imageMigrationTarget.\(userID)"
    }

    private var storageKey: String { Self.storageKey(for: userID) }
    private var targetStorageKey: String { Self.targetStorageKey(for: userID) }

    // MARK: - API

    /// 현재 보유한 마이그레이션 대상 이미지 목록 (영속화 + 메모리). 완료됐거나 미설정이면 빈 배열.
    var currentTarget: [MemoImageInfo] {
        lock.withLock { totalImageInfos }
    }

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

    /// 마이그레이션 대상 이미지 목록을 알려줘 영속화하고 progress 계산의 기준으로 삼는다.
    /// 이후 mark 시점마다 자동으로 (completed, total) snapshot 을 emit. 모두 완료되면 영속화도
    /// 자동 삭제 + nil emit.
    func setProgressTarget(_ infos: [MemoImageInfo]) {
        lock.withLock {
            totalImageInfos = infos
            saveTarget(infos)
        }
        recalculateAndEmit()
    }

    /// progress 표시 + 영속화된 target 을 명시적으로 삭제 (sign-out 등).
    func clearProgressTarget() {
        lock.withLock {
            totalImageInfos = []
            userDefaults.removeObject(forKey: targetStorageKey)
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

    private func saveTarget(_ infos: [MemoImageInfo]) {
        guard let data = try? JSONEncoder().encode(infos) else {
            userDefaults.removeObject(forKey: targetStorageKey)
            return
        }
        userDefaults.set(data, forKey: targetStorageKey)
    }

    private static func loadTarget(userID: String, userDefaults: UserDefaults) -> [MemoImageInfo] {
        guard let data = userDefaults.data(forKey: targetStorageKey(for: userID)) else { return [] }
        return (try? JSONDecoder().decode([MemoImageInfo].self, from: data)) ?? []
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
            // 완료 — 영속화된 target 자동 삭제 (재진입 시 "이미 끝남" 으로 해석) + nil emit (row hide).
            lock.withLock {
                totalImageInfos = []
                userDefaults.removeObject(forKey: targetStorageKey)
            }
            progressSubject.send(nil)
        } else {
            progressSubject.send(UploadProgressSnapshot(
                completedImageCount: completed,
                totalImageCount: infos.count
            ))
        }
    }
}
