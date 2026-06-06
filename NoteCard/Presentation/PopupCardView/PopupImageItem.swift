//
//  PopupImageItem.swift
//  NoteCard
//

import Domain
import UIKit

/// PopupCard 의 collection view 가 사용하는 단일 항목 모델.
/// 메타데이터는 즉시 받고 thumbnail binary 는 비동기 로드되는 구조라
/// 모델이 로딩 / 성공 / 실패 상태를 들고 있어야 함.
struct PopupImageItem {
    let info: MemoImageInfo
    var thumbnailState: ImageLoadState
}
