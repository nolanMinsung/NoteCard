//
//  UploadProgressObservable.swift
//  NoteCard
//

import Combine
import Foundation

/// 첫 sign-in 마이그레이션의 이미지 바이너리 업로드 진행 상황을 UI 가 관찰할 수 있게 노출.
/// `nil` 은 표시할 진행이 없음 (idle / 완료 / sign-out) — UI 는 표시를 숨김.
public protocol UploadProgressObservable: Sendable {
    var imageUploadProgressPublisher: AnyPublisher<UploadProgressSnapshot?, Never> { get }
}
