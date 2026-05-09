import Foundation

/// Type-safe wrapper around Localizable.xcstrings.
/// Use `L10n.<group>.<name>` instead of bare `"...".localized()` for compile-time safety.
enum L10n {
    enum Date {
        static let today = "오늘".localized()
        static let yesterday = "어제".localized()
        static let createdOn = "%@에 생성됨".localized()
        static let editedOn = "%@에 수정됨".localized()
        static let willBeDeletedInDays = "%d일 뒤에 삭제됨".localized()
        static let willBeDeletedWithin24h = "1일 이내에 삭제됨".localized()
    }

    enum TabBar {
        static let home = "홈 화면".localized()
        static let uncategorized = "카테고리 없음".localized()
        static let quickMemo = "빠른 메모".localized()
        static let searchMemo = "메모 검색".localized()
        static let settings = "설정".localized()
    }

    enum Home {
        static let category = "카테고리".localized()
        static let favorites = "즐겨찾기".localized()
        static let allMemos = "전체 메모".localized()
        static let makeCategory = "카테고리 만들기".localized()
        static let noFavorites = "즐겨찾기 없음".localized()
    }

    enum CategoryList {
        static let allCategoriesTitle = "전체 카테고리 목록".localized()
        static let rename = "이름 변경".localized()
        static let renameCategory = "카테고리 이름 변경".localized()
        static let enterNewCategoryName = "새 카테고리 이름을 입력하세요".localized()
        static let duplicateName = "이름 중복".localized()
        static let duplicateNameMessage = "같은 이름의 카테고리가 있습니다. 다른 이름을 입력해주세요.".localized()
        static let deleteCategory = "카테고리 삭제".localized()
        static let deleteCategoryConfirm = "카테고리를 삭제하시겠습니까?\n카테고리에 속한 메모들은 삭제되지 않습니다.".localized()
    }

    enum CreateCategory {
        static let createCategoryTitle = "카테고리 생성".localized()
        static let categoryNamePlaceholder = "카테고리 이름 입력".localized()
        static let emptyCategoryName = "카테고리 이름이 비었습니다.".localized()
        static let emptyCategoryNameMessage = "카테고리 이름을 입력하여 카테고리를 추가하세요.".localized()
    }

    enum PopupCard {
        static let recoverAsUncategorizedSingle = "카테고리 없는 메모로 복구".localized()
        static let recoverThisMemoConfirm = "이 메모를 복구하시겠습니까?".localized()
        static let recoverThisMemoMessage = "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized()
        static let deleteThisMemo = "이 메모 삭제하기".localized()
        static let deleteSelectedMemoConfirm = "선택한 메모를 영구적으로 삭제하시겠습니까?".localized()
        static let deleteMemoTitle = "메모 삭제".localized()
        static let deleteMemoConfirm = "메모를 삭제하시겠습니까?".localized()
        static let noTitle = "제목 없음".localized()
    }

    enum MemoView {
        static let recoverAsUncategorizedMultiple = "카테고리 없는 메모들로 복구".localized()
        static let recoverTheseMemosConfirm = "이 메모들을 복구하시겠습니까?".localized()
        static let recoverTheseMemosMessage = "복구된 메모들은 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized()
        static let selectCategoriesToRecover = "복구할 카테고리 선택".localized()
        static let batchAddCategories = "카테고리 일괄 추가".localized()
        static let batchRemoveCategories = "카테고리 일괄 해제".localized()
        static let addToFavorites = "즐겨찾기에 추가".localized()
        static let removeFromFavorites = "즐겨찾기에 해제".localized()
        static let memosSelectedFormat = "%d개의 메모 선택됨".localized()
        static let favoriteMemos = "즐겨찾기한 메모".localized()
        static let allMemosTitle = "전체 메모 목록".localized()
        static let trash = "휴지통".localized()
        static let deleteSelectedMemosConfirm = "선택한 메모들을 영구적으로 삭제하시겠습니까?".localized()
        static let deleteSelectedMemos = "선택된 메모 삭제".localized()
        static let deleteSelectedMemosMessage = "선택한 메모들을 모두 삭제하시겠습니까?".localized()
        static let categoryNameCannotBeEmpty = "카테고리 이름을 비울 수 없습니다.".localized()
    }

    enum CategorySelection {
        static let selectCategoryTitle = "카테고리 선택하기".localized()
        static let categoriesSelectedFormat = "%d개의 카테고리 선택됨".localized()
    }

    enum MemoDetail {
        static let writeMemoPlaceholder = "메모를 입력하세요.".localized()
        static let memoIsEmpty = "메모 내용이 없습니다.".localized()
        static let cancelMemoCreation = "메모 작성 취소".localized()
        static let cancelMemoCreationConfirm = "메모 작성을 취소하시겠습니까?".localized()
        static let continueWriting = "계속 작성".localized()
        static let addMemo = "메모 추가하기".localized()
        static let imageLimitExceeded = "이미지 한도 초과".localized()
        static let imageLimitMessage = "메모당 이미지 저장은 최대 10개까지 가능합니다.".localized()
    }

    enum Settings {
        static let themeColor = "테마 색".localized()
        static let dateFormat = "날짜 표시 형식".localized()
        static let timeFormat = "시간 표시 형식".localized()
        static let displayOrder = "표시 순서".localized()
        static let darkMode = "다크 모드".localized()
        static let totalMemos = "총 메모 수".localized()
        static let totalCategories = "총 카테고리 수".localized()
        static let emptyTrash = "휴지통 비우기".localized()
        static let contactDeveloper = "개발자 이메일".localized()
        static let rateApp = "별점/리뷰 남기기".localized()
        static let version = "버전 정보".localized()
        static let placeholderText = "Settings_Placeholder_text".localized()
        static let trashRetentionMessage = "휴지통에 들어간 메모는 삭제된 지 2주가 지나면 영구적으로 삭제됩니다.".localized()
        static let emptyTrashConfirm = "휴지통의 모든 메모가 삭제됩니다.\n이 동작은 취소할 수 없습니다.".localized()
        static let selectThemeColor = "테마 색 선택".localized()
        static let memoSortingTitle = "메모 순서 표시".localized()
        static let memoSortingCriteria = "메모 정렬 기준".localized()
        static let lightMode = "라이트 모드".localized()
        static let systemMode = "시스템 모드".localized()
        static let modificationTime = "수정 시간".localized()
        static let creationTime = "만든 시간".localized()
        static let ascending = "오름차순".localized()
        static let descending = "내림차순".localized()
        static let modificationLabel = "SettingsVC/수정 시간".localized()
        static let creationLabel = "SettingsVC/만든 시간".localized()
        static let ascendingLabel = "SettingsVC/오름차순".localized()
        static let descendingLabel = "SettingsVC/내림차순".localized()
        static let format24h = "24시간제".localized()
        static let format12h = "12시간제".localized()
    }

    enum ThemeColor {
        static let blackWhite = "Black/White".localized()
        static let brown = "Brown".localized()
        static let red = "Red".localized()
        static let orange = "Orange".localized()
        static let yellow = "Yellow".localized()
        static let green = "Green".localized()
        static let skyblue = "Skyblue".localized()
        static let blue = "Blue".localized()
        static let purple = "Purple".localized()
        static let black = "Black".localized()
    }

    enum Common {
        static let cancel = "취소".localized()
        static let ok = "확인".localized()
        static let save = "저장".localized()
        static let delete = "삭제".localized()
        static let done = "완료".localized()
        static let add = "추가".localized()
        static let remove = "해제".localized()
        static let select = "선택".localized()
        static let editingMode = "편집 모드".localized()
        static let recover = "복구".localized()
        static let alert = "알림".localized()
        static let actionCannotBeUndone = "이 동작은 취소할 수 없습니다.".localized()
    }

}
