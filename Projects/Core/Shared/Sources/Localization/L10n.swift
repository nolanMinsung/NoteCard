import Foundation

/// Type-safe wrapper around Localizable.xcstrings.
/// Use `L10n.<group>.<name>` instead of bare `"...".localized()` for compile-time safety.
public enum L10n {
    public enum Date {
        public static let today = "date.today".localized()
        public static let yesterday = "date.yesterday".localized()
        public static let createdOn = "date.createdOn".localized()
        public static let editedOn = "date.editedOn".localized()
        public static let willBeDeletedInDays = "date.willBeDeletedInDays".localized()
        public static let willBeDeletedWithin24h = "date.willBeDeletedWithin24h".localized()
    }

    public enum TabBar {
        public static let home = "tabBar.home".localized()
        public static let uncategorized = "tabBar.uncategorized".localized()
        public static let quickMemo = "tabBar.quickMemo".localized()
        public static let searchMemo = "tabBar.searchMemo".localized()
        public static let settings = "tabBar.settings".localized()
    }

    public enum Home {
        public static let category = "home.category".localized()
        public static let favorites = "home.favorites".localized()
        public static let allMemos = "home.allMemos".localized()
        public static let makeCategory = "home.makeCategory".localized()
        public static let noFavorites = "home.noFavorites".localized()
        public static let addCategoryPlaceholder = "home.addCategoryPlaceholder".localized()
        public static let addMemoPlaceholder = "home.addMemoPlaceholder".localized()
    }

    public enum CategoryList {
        public static let allCategoriesTitle = "categoryList.allCategoriesTitle".localized()
        public static let rename = "categoryList.rename".localized()
        public static let renameCategory = "categoryList.renameCategory".localized()
        public static let enterNewCategoryName = "categoryList.enterNewCategoryName".localized()
        public static let duplicateName = "categoryList.duplicateName".localized()
        public static let duplicateNameMessage = "categoryList.duplicateNameMessage".localized()
        public static let deleteCategory = "categoryList.deleteCategory".localized()
        public static let deleteCategoryConfirm = "categoryList.deleteCategoryConfirm".localized()
    }

    public enum CreateCategory {
        public static let createCategoryTitle = "createCategory.createCategoryTitle".localized()
        public static let categoryNamePlaceholder = "createCategory.categoryNamePlaceholder".localized()
        public static let emptyCategoryName = "createCategory.emptyCategoryName".localized()
        public static let emptyCategoryNameMessage = "createCategory.emptyCategoryNameMessage".localized()
    }

    public enum PopupCard {
        public static let recoverAsUncategorizedSingle = "popupCard.recoverAsUncategorizedSingle".localized()
        public static let recoverThisMemoConfirm = "popupCard.recoverThisMemoConfirm".localized()
        public static let recoverThisMemoMessage = "popupCard.recoverThisMemoMessage".localized()
        public static let deleteThisMemo = "popupCard.deleteThisMemo".localized()
        public static let deleteSelectedMemoConfirm = "popupCard.deleteSelectedMemoConfirm".localized()
        public static let deleteMemoTitle = "popupCard.deleteMemoTitle".localized()
        public static let deleteMemoConfirm = "popupCard.deleteMemoConfirm".localized()
        public static let noTitle = "popupCard.noTitle".localized()
    }

    public enum MemoView {
        public static let recoverAsUncategorizedMultiple = "memoView.recoverAsUncategorizedMultiple".localized()
        public static let recoverTheseMemosConfirm = "memoView.recoverTheseMemosConfirm".localized()
        public static let recoverTheseMemosMessage = "memoView.recoverTheseMemosMessage".localized()
        public static let selectCategoriesToRecover = "memoView.selectCategoriesToRecover".localized()
        public static let batchAddCategories = "memoView.batchAddCategories".localized()
        public static let batchRemoveCategories = "memoView.batchRemoveCategories".localized()
        public static let addToFavorites = "memoView.addToFavorites".localized()
        public static let removeFromFavorites = "memoView.removeFromFavorites".localized()
        public static let memosSelectedFormat = "memoView.memosSelectedFormat".localized()
        public static let favoriteMemos = "memoView.favoriteMemos".localized()
        public static let allMemosTitle = "memoView.allMemosTitle".localized()
        public static let trash = "memoView.trash".localized()
        public static let deleteSelectedMemosConfirm = "memoView.deleteSelectedMemosConfirm".localized()
        public static let deleteSelectedMemos = "memoView.deleteSelectedMemos".localized()
        public static let deleteSelectedMemosMessage = "memoView.deleteSelectedMemosMessage".localized()
        public static let categoryNameCannotBeEmpty = "memoView.categoryNameCannotBeEmpty".localized()
    }

    public enum CategorySelection {
        public static let selectCategoryTitle = "categorySelection.selectCategoryTitle".localized()
        public static let categoriesSelectedFormat = "categorySelection.categoriesSelectedFormat".localized()
    }

    public enum MemoDetail {
        public static let writeMemoPlaceholder = "memoDetail.writeMemoPlaceholder".localized()
        public static let memoIsEmpty = "memoDetail.memoIsEmpty".localized()
        public static let cancelMemoCreation = "memoDetail.cancelMemoCreation".localized()
        public static let cancelMemoCreationConfirm = "memoDetail.cancelMemoCreationConfirm".localized()
        public static let continueWriting = "memoDetail.continueWriting".localized()
        public static let addMemo = "memoDetail.addMemo".localized()
        public static let imageLimitExceeded = "memoDetail.imageLimitExceeded".localized()
        public static let imageLimitMessage = "memoDetail.imageLimitMessage".localized()
    }

    public enum Settings {
        public static let themeColor = "settings.themeColor".localized()
        public static let dateFormat = "settings.dateFormat".localized()
        public static let timeFormat = "settings.timeFormat".localized()
        public static let displayOrder = "settings.displayOrder".localized()
        public static let darkMode = "settings.darkMode".localized()
        public static let totalMemos = "settings.totalMemos".localized()
        public static let totalCategories = "settings.totalCategories".localized()
        public static let emptyTrash = "settings.emptyTrash".localized()
        public static let contactDeveloper = "settings.contactDeveloper".localized()
        public static let rateApp = "settings.rateApp".localized()
        public static let version = "settings.version".localized()
        public static let placeholderText = "settings.placeholderText".localized()
        public static let trashRetentionMessage = "settings.trashRetentionMessage".localized()
        public static let emptyTrashConfirm = "settings.emptyTrashConfirm".localized()
        public static let selectThemeColor = "settings.selectThemeColor".localized()
        public static let memoSortingTitle = "settings.memoSortingTitle".localized()
        public static let memoSortingCriteria = "settings.memoSortingCriteria".localized()
        public static let lightMode = "settings.lightMode".localized()
        public static let systemMode = "settings.systemMode".localized()
        public static let modificationTime = "settings.modificationTime".localized()
        public static let creationTime = "settings.creationTime".localized()
        public static let ascending = "settings.ascending".localized()
        public static let descending = "settings.descending".localized()
        public static let modificationLabel = "settings.modificationLabel".localized()
        public static let creationLabel = "settings.creationLabel".localized()
        public static let ascendingLabel = "settings.ascendingLabel".localized()
        public static let descendingLabel = "settings.descendingLabel".localized()
        public static let format24h = "settings.format24h".localized()
        public static let format12h = "settings.format12h".localized()
    }

    public enum ThemeColor {
        public static let blackWhite = "themeColor.blackWhite".localized()
        public static let brown = "themeColor.brown".localized()
        public static let red = "themeColor.red".localized()
        public static let orange = "themeColor.orange".localized()
        public static let yellow = "themeColor.yellow".localized()
        public static let green = "themeColor.green".localized()
        public static let skyblue = "themeColor.skyblue".localized()
        public static let blue = "themeColor.blue".localized()
        public static let purple = "themeColor.purple".localized()
        public static let black = "themeColor.black".localized()
    }

    public enum Common {
        public static let cancel = "common.cancel".localized()
        public static let ok = "common.ok".localized()
        public static let save = "common.save".localized()
        public static let delete = "common.delete".localized()
        public static let done = "common.done".localized()
        public static let add = "common.add".localized()
        public static let remove = "common.remove".localized()
        public static let select = "common.select".localized()
        public static let editingMode = "common.editingMode".localized()
        public static let more = "common.more".localized()
        public static let recover = "common.recover".localized()
        public static let alert = "common.alert".localized()
        public static let actionCannotBeUndone = "common.actionCannotBeUndone".localized()
    }

}
