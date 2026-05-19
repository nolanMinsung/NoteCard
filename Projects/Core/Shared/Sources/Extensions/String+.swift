//
//  String+.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import Foundation


public extension String {

    /// `Localizable.xcstrings`는 Shared 모듈로 옮겨졌으므로 기본 bundle을
    /// SharedResources.bundle로 둔다. 다른 모듈이 자체 Localization을 가질 경우
    /// 호출부에서 bundle을 명시 전달.
    func localized(
        value: String = "localized 필요",
        comment: String = "",
        bundle: Bundle = SharedResources.bundle
    ) -> String {
        return NSLocalizedString(self, bundle: bundle, value: value, comment: comment)
    }

}
