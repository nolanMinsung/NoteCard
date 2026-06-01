//
//  ImageRepository.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import Combine
import PhotosUI
import Shared
import UIKit

// MARK: - Repository Protocol
public protocol ImageRepository: Sendable {

    var imageUpdatedPublisher: AnyPublisher<ImageUpdateType, Never> { get }

    func createImage(
        from pickerResult: PHPickerResult,
        for memo: Memo,
        originalImageID: UUID?,
        thumbnailID: UUID?,
        orderIndex: Int,
        isTemporary: Bool
    ) async throws -> MemoImageInfo
    
    func getImage(from imageInfo: MemoImageInfo) async throws -> UIImage
    func getThumbnailImage(from imageInfo: MemoImageInfo) async throws -> UIImage
    func getAllImageInfo(for memo: Memo) async throws -> [MemoImageInfo]
    func updateImageIndex(_ image: MemoImageInfo, newIndex: Int) async throws
    func deleteImage(_ imageInfo: MemoImageInfo) async throws

    /// 메모의 이미지 변경을 구독. 반환된 cancellable의 cancel 시점에 listener detach.
    /// 활성 구간 동안 발생한 이벤트는 `imageUpdatedPublisher` 로 emit.
    func observeImageChanges(for memoID: UUID) -> AnyCancellable
}
