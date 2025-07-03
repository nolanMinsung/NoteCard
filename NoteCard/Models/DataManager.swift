//
//  DataManager.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

enum MemoProperties: String {
    
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

enum CategoryProperties: String {
    case name
    case creationDate
    case modificationDate
    case categoryDirectoryURL
}

enum ImageOrderIndexKind: String {
    case orderIndex
    case temporaryOrderIndex
}

enum UserDefaultsKeys: String {
    case themeColor
    case dateFormat
    case isTimeFormat24
    case locale
    case orderCriterion
    case isOrderAscending
    case darkModeTheme
}

enum OrderCriterion: String, CaseIterable {
    case modificationDate
    case creationDate
//    case memoTitle
}


enum DarkModeTheme: String, CaseIterable {
    case light
    case dark
    case systemTheme
}


struct CGSizeConstant {
    static let screenSize = UIScreen.current!.bounds.size
    static let popupCardThumbnailSize = CGSize(width: 70, height: 70)
    static let detailViewThumbnailSize = CGSize(width: 70, height: 70)
    static let compositionalCardThumbnailSize = CGSize(width: 70, height: 70)
}


enum NotificationName: String {
    case cellSelectedNotification
    case themeColorChangedNotification
    
    case createdMemoNotification
    case editingCompleteNotification
    case memoTrashedNotification
    case memoRecoveredToUncategorizedNotification
}
