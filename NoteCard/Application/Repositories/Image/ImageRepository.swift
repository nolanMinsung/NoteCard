//
//  ImageRepository.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import PhotosUI
import UIKit

// MARK: - Repository Protocol
protocol ImageRepository {
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
    func deleteImage(_ imageInfo: MemoImageInfo) async throws
}
