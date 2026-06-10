//
//  TightBackgroundLayoutManager.swift
//  NoteCard
//
//  Created by 김민성 on 6/9/26.
//

import UIKit

/// `.backgroundColor` 속성을 그릴 때 line fragment 에 포함된 행간(lineSpacing)만큼
/// 아래쪽을 깎아, 하이라이트가 글자 영역보다 길게 늘어지지 않도록 하는 NSLayoutManager.
///
/// 기본 NSLayoutManager 는 배경색을 line fragment rect 전체(= 글자 높이 + 행간)에 칠하기 때문에
/// 행간만큼 하이라이트가 다음 줄 쪽으로 늘어나 보인다.
final class TightBackgroundLayoutManager: NSLayoutManager {

    /// 본문에 적용된 행간. 배경 사각형 높이에서 이만큼을 덜어낸다.
    var lineSpacing: CGFloat = 5

    override func fillBackgroundRectArray(
        _ rectArray: UnsafePointer<CGRect>,
        count rectCount: Int,
        forCharacterRange charRange: NSRange,
        color: UIColor
    ) {
        color.setFill()
        for index in 0..<rectCount {
            var rect = rectArray[index]
            rect.size.height = max(0, rect.size.height - lineSpacing)
            UIBezierPath(rect: rect).fill()
        }
    }

}
