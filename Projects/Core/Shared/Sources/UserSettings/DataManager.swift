//
//  DataManager.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

public enum MemoProperties: String {
    
    case creationDate
    case isFavorite
    case latitude
    case longitude
    case memoText
    case memoTitle
    case modificationDate
    case categories
    case images
    case trashCan
    case deletedDate
}

public enum CategoryProperties: String {
    case name
    case creationDate
    case modificationDate
}

public enum ImageOrderIndexKind: String {
    case orderIndex
    case temporaryOrderIndex
}

public enum UserDefaultsKeys: String {
    case themeColor
    case dateFormat
    case isTimeFormat24
    case locale
    case orderCriterion
    case isOrderAscending
    case darkModeTheme
}

public enum OrderCriterion: String, CaseIterable {
    case modificationDate
    case creationDate
//    case memoTitle
}


public enum DarkModeTheme: String, CaseIterable {
    case light
    case dark
    case systemTheme
}


public struct CGSizeConstant {
    public static let screenSize = UIScreen.current!.bounds.size
    public static let popupCardThumbnailSize = CGSize(width: 70, height: 70)
    public static let detailViewThumbnailSize = CGSize(width: 90, height: 90)
    public static let compositionalCardThumbnailSize = CGSize(width: 70, height: 70)
}


public enum NotificationName: String {
    case cellSelectedNotification
    case createdMemoNotification
    case editingCompleteNotification
    case memoTrashedNotification
    case memoRecoveredToUncategorizedNotification
}
