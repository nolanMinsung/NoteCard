//
//  ImageLoading.swift
//  NoteCard
//

import UIKit

/// 비동기 이미지 로딩의 셀 표시 상태.
enum ImageLoadState {
    case loading
    case loaded(UIImage)
    case failed
}

enum ImageLoadingHelper {
    /// transient 실패 (네트워크 일시 끊김, token propagation 지연 등) 대응. 1초 → 3초 backoff 후 포기.
    static func loadWithRetry<T>(_ work: @escaping () async throws -> T) async -> Result<T, Error> {
        let backoffsNs: [UInt64] = [1_000_000_000, 3_000_000_000]
        var lastError: Error?
        for attempt in 0...backoffsNs.count {
            do {
                return .success(try await work())
            } catch {
                lastError = error
                if attempt < backoffsNs.count {
                    try? await Task.sleep(nanoseconds: backoffsNs[attempt])
                }
            }
        }
        return .failure(lastError ?? CancellationError())
    }
}
