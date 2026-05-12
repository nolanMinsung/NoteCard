import Foundation

/// Type-safe wrapper around Localizable.xcstrings.
/// Use `L10n.<group>.<name>` instead of bare `"...".localized()` for compile-time safety.
enum L10n {
    enum Date {
        static let today = "date.today".localized()
        static let yesterday = "date.yesterday".localized()
        static let createdOn = "date.createdOn".localized()
        static let editedOn = "date.editedOn".localized()
        static let willBeDeletedInDays = "date.willBeDeletedInDays".localized()
        static let willBeDeletedWithin24h = "date.willBeDeletedWithin24h".localized()
    }

    enum TabBar {
        static let home = "tabBar.home".localized()
        static let uncategorized = "tabBar.uncategorized".localized()
        static let quickMemo = "tabBar.quickMemo".localized()
        static let searchMemo = "tabBar.searchMemo".localized()
        static let settings = "tabBar.settings".localized()
    }

    enum Home {
        static let category = "home.category".localized()
        static let favorites = "home.favorites".localized()
        static let allMemos = "home.allMemos".localized()
        static let makeCategory = "home.makeCategory".localized()
        static let noFavorites = "home.noFavorites".localized()
        static let addCategoryPlaceholder = "home.addCategoryPlaceholder".localized()
        static let addMemoPlaceholder = "home.addMemoPlaceholder".localized()
    }

    enum CategoryList {
        static let allCategoriesTitle = "categoryList.allCategoriesTitle".localized()
        static let rename = "categoryList.rename".localized()
        static let renameCategory = "categoryList.renameCategory".localized()
        static let enterNewCategoryName = "categoryList.enterNewCategoryName".localized()
        static let duplicateName = "categoryList.duplicateName".localized()
        static let duplicateNameMessage = "categoryList.duplicateNameMessage".localized()
        static let deleteCategory = "categoryList.deleteCategory".localized()
        static let deleteCategoryConfirm = "categoryList.deleteCategoryConfirm".localized()
    }

    enum CreateCategory {
        static let createCategoryTitle = "createCategory.createCategoryTitle".localized()
        static let categoryNamePlaceholder = "createCategory.categoryNamePlaceholder".localized()
        static let emptyCategoryName = "createCategory.emptyCategoryName".localized()
        static let emptyCategoryNameMessage = "createCategory.emptyCategoryNameMessage".localized()
    }

    enum PopupCard {
        static let recoverAsUncategorizedSingle = "popupCard.recoverAsUncategorizedSingle".localized()
        static let recoverThisMemoConfirm = "popupCard.recoverThisMemoConfirm".localized()
        static let recoverThisMemoMessage = "popupCard.recoverThisMemoMessage".localized()
        static let deleteThisMemo = "popupCard.deleteThisMemo".localized()
        static let deleteSelectedMemoConfirm = "popupCard.deleteSelectedMemoConfirm".localized()
        static let deleteMemoTitle = "popupCard.deleteMemoTitle".localized()
        static let deleteMemoConfirm = "popupCard.deleteMemoConfirm".localized()
        static let noTitle = "popupCard.noTitle".localized()
    }

    enum MemoView {
        static let recoverAsUncategorizedMultiple = "memoView.recoverAsUncategorizedMultiple".localized()
        static let recoverTheseMemosConfirm = "memoView.recoverTheseMemosConfirm".localized()
        static let recoverTheseMemosMessage = "memoView.recoverTheseMemosMessage".localized()
        static let selectCategoriesToRecover = "memoView.selectCategoriesToRecover".localized()
        static let batchAddCategories = "memoView.batchAddCategories".localized()
        static let batchRemoveCategories = "memoView.batchRemoveCategories".localized()
        static let addToFavorites = "memoView.addToFavorites".localized()
        static let removeFromFavorites = "memoView.removeFromFavorites".localized()
        static let memosSelectedFormat = "memoView.memosSelectedFormat".localized()
        static let favoriteMemos = "memoView.favoriteMemos".localized()
        static let allMemosTitle = "memoView.allMemosTitle".localized()
        static let trash = "memoView.trash".localized()
        static let deleteSelectedMemosConfirm = "memoView.deleteSelectedMemosConfirm".localized()
        static let deleteSelectedMemos = "memoView.deleteSelectedMemos".localized()
        static let deleteSelectedMemosMessage = "memoView.deleteSelectedMemosMessage".localized()
        static let categoryNameCannotBeEmpty = "memoView.categoryNameCannotBeEmpty".localized()
    }

    enum CategorySelection {
        static let selectCategoryTitle = "categorySelection.selectCategoryTitle".localized()
        static let categoriesSelectedFormat = "categorySelection.categoriesSelectedFormat".localized()
    }

    enum MemoDetail {
        static let writeMemoPlaceholder = "memoDetail.writeMemoPlaceholder".localized()
        static let memoIsEmpty = "memoDetail.memoIsEmpty".localized()
        static let cancelMemoCreation = "memoDetail.cancelMemoCreation".localized()
        static let cancelMemoCreationConfirm = "memoDetail.cancelMemoCreationConfirm".localized()
        static let continueWriting = "memoDetail.continueWriting".localized()
        static let addMemo = "memoDetail.addMemo".localized()
        static let imageLimitExceeded = "memoDetail.imageLimitExceeded".localized()
        static let imageLimitMessage = "memoDetail.imageLimitMessage".localized()
    }

    enum Settings {
        static let themeColor = "settings.themeColor".localized()
        static let dateFormat = "settings.dateFormat".localized()
        static let timeFormat = "settings.timeFormat".localized()
        static let displayOrder = "settings.displayOrder".localized()
        static let darkMode = "settings.darkMode".localized()
        static let totalMemos = "settings.totalMemos".localized()
        static let totalCategories = "settings.totalCategories".localized()
        static let emptyTrash = "settings.emptyTrash".localized()
        static let contactDeveloper = "settings.contactDeveloper".localized()
        static let rateApp = "settings.rateApp".localized()
        static let version = "settings.version".localized()
        static let placeholderText = "settings.placeholderText".localized()
        static let trashRetentionMessage = "settings.trashRetentionMessage".localized()
        static let emptyTrashConfirm = "settings.emptyTrashConfirm".localized()
        static let selectThemeColor = "settings.selectThemeColor".localized()
        static let memoSortingTitle = "settings.memoSortingTitle".localized()
        static let memoSortingCriteria = "settings.memoSortingCriteria".localized()
        static let lightMode = "settings.lightMode".localized()
        static let systemMode = "settings.systemMode".localized()
        static let modificationTime = "settings.modificationTime".localized()
        static let creationTime = "settings.creationTime".localized()
        static let ascending = "settings.ascending".localized()
        static let descending = "settings.descending".localized()
        static let modificationLabel = "settings.modificationLabel".localized()
        static let creationLabel = "settings.creationLabel".localized()
        static let ascendingLabel = "settings.ascendingLabel".localized()
        static let descendingLabel = "settings.descendingLabel".localized()
        static let format24h = "settings.format24h".localized()
        static let format12h = "settings.format12h".localized()
    }

    enum ThemeColor {
        static let blackWhite = "themeColor.blackWhite".localized()
        static let brown = "themeColor.brown".localized()
        static let red = "themeColor.red".localized()
        static let orange = "themeColor.orange".localized()
        static let yellow = "themeColor.yellow".localized()
        static let green = "themeColor.green".localized()
        static let skyblue = "themeColor.skyblue".localized()
        static let blue = "themeColor.blue".localized()
        static let purple = "themeColor.purple".localized()
        static let black = "themeColor.black".localized()
    }

    enum Common {
        static let cancel = "common.cancel".localized()
        static let ok = "common.ok".localized()
        static let save = "common.save".localized()
        static let delete = "common.delete".localized()
        static let done = "common.done".localized()
        static let add = "common.add".localized()
        static let remove = "common.remove".localized()
        static let select = "common.select".localized()
        static let editingMode = "common.editingMode".localized()
        static let more = "common.more".localized()
        static let recover = "common.recover".localized()
        static let alert = "common.alert".localized()
        static let actionCannotBeUndone = "common.actionCannotBeUndone".localized()
    }

}
