//
//  ImageLoading.swift
//  NoteCard
//

import Data
import Domain
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

    /// 로컬 캐시(Documents)에 이미지가 이미 있으면 sync 로 즉시 로드. 없으면 nil.
    /// 캐시 hit 시 loading spinner 없이 즉시 표시하기 위함.
    static func loadCachedImage(for info: MemoImageInfo, thumbnail: Bool) -> UIImage? {
        do {
            let url = try ImageFileHandler.getFileURL(for: info, thumbnail: thumbnail)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return try ImageFileHandler.loadUIImage(from: url)
        } catch {
            return nil
        }
    }
}
