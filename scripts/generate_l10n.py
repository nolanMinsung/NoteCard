#!/usr/bin/env python3
"""Generate L10n.swift from Localizable.xcstrings and produce a key→identifier mapping."""
import json
import re
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
XCSTRINGS = os.path.join(ROOT, 'NoteCard/Localizable.xcstrings')
OUTPUT_SWIFT = os.path.join(ROOT, 'NoteCard/Global/Localization/L10n.swift')
MAPPING_JSON = '/tmp/l10n_mapping.json'

# Group keys by feature/screen. Each Korean key maps into one logical group.
GROUPS = {
    "Date": ["오늘", "어제", "%@에 생성됨", "%@에 수정됨", "%d일 뒤에 삭제됨", "1일 이내에 삭제됨"],
    "TabBar": ["홈 화면", "카테고리 없음", "빠른 메모", "메모 검색", "설정"],
    "Home": ["카테고리", "즐겨찾기", "전체 메모", "카테고리 만들기", "즐겨찾기 없음"],
    "CategoryList": [
        "전체 카테고리 목록", "이름 변경", "카테고리 이름 변경", "새 카테고리 이름을 입력하세요",
        "이름 중복", "같은 이름의 카테고리가 있습니다. 다른 이름을 입력해주세요.",
        "카테고리 삭제",
        "카테고리를 삭제하시겠습니까?\n카테고리에 속한 메모들은 삭제되지 않습니다.",
    ],
    "CreateCategory": [
        "카테고리 생성", "카테고리 이름 입력", "카테고리 이름이 비었습니다.",
        "카테고리 이름을 입력하여 카테고리를 추가하세요.",
    ],
    "PopupCard": [
        "카테고리 없는 메모로 복구", "이 메모를 복구하시겠습니까?",
        "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.",
        "이 메모 삭제하기", "선택한 메모를 영구적으로 삭제하시겠습니까?",
        "메모 삭제", "메모를 삭제하시겠습니까?", "제목 없음",
    ],
    "MemoView": [
        "카테고리 없는 메모들로 복구", "이 메모들을 복구하시겠습니까?",
        "복구된 메모들은 '카테고리 없음' 항목에서 확인할 수 있습니다.",
        "복구할 카테고리 선택", "카테고리 일괄 추가", "카테고리 일괄 해제",
        "즐겨찾기에 추가", "즐겨찾기에 해제", "%d개의 메모 선택됨",
        "즐겨찾기한 메모", "전체 메모 목록", "휴지통",
        "선택한 메모들을 영구적으로 삭제하시겠습니까?", "선택된 메모 삭제",
        "선택한 메모들을 모두 삭제하시겠습니까?",
        "카테고리 이름을 비울 수 없습니다.",
    ],
    "CategorySelection": ["카테고리 선택하기", "%d개의 카테고리 선택됨"],
    "MemoDetail": [
        "메모를 입력하세요.", "메모 내용이 없습니다.",
        "메모 작성 취소", "메모 작성을 취소하시겠습니까?", "계속 작성",
        "메모 추가하기", "이미지 한도 초과", "메모당 이미지 저장은 최대 10개까지 가능합니다.",
    ],
    "Settings": [
        "테마 색", "날짜 표시 형식", "시간 표시 형식", "표시 순서", "다크 모드",
        "총 메모 수", "총 카테고리 수", "휴지통 비우기",
        "개발자 이메일", "별점/리뷰 남기기", "버전 정보",
        "Settings_Placeholder_text",
        "휴지통에 들어간 메모는 삭제된 지 2주가 지나면 영구적으로 삭제됩니다.",
        "휴지통의 모든 메모가 삭제됩니다.\n이 동작은 취소할 수 없습니다.",
        "테마 색 선택", "메모 순서 표시", "메모 정렬 기준",
        "라이트 모드", "시스템 모드",
        "수정 시간", "만든 시간", "오름차순", "내림차순",
        "SettingsVC/수정 시간", "SettingsVC/만든 시간",
        "SettingsVC/오름차순", "SettingsVC/내림차순",
        "24시간제", "12시간제",
    ],
    "ThemeColor": [
        "Black/White", "Brown", "Red", "Orange", "Yellow",
        "Green", "Skyblue", "Blue", "Purple", "Black",
    ],
    "Common": [
        "취소", "확인", "저장", "삭제", "완료", "추가", "해제", "선택",
        "편집 모드", "복구", "알림", "이 동작은 취소할 수 없습니다.",
    ],
}

# Hand-curated identifier names for each key (Korean → camelCase Swift identifier).
# Names chosen to be descriptive based on the English translation or Korean meaning.
IDENTIFIERS = {
    # Date
    "오늘": "today",
    "어제": "yesterday",
    "%@에 생성됨": "createdOn",
    "%@에 수정됨": "editedOn",
    "%d일 뒤에 삭제됨": "willBeDeletedInDays",
    "1일 이내에 삭제됨": "willBeDeletedWithin24h",
    # TabBar
    "홈 화면": "home",
    "카테고리 없음": "uncategorized",
    "빠른 메모": "quickMemo",
    "메모 검색": "searchMemo",
    "설정": "settings",
    # Home
    "카테고리": "category",
    "즐겨찾기": "favorites",
    "전체 메모": "allMemos",
    "카테고리 만들기": "makeCategory",
    "즐겨찾기 없음": "noFavorites",
    # CategoryList
    "전체 카테고리 목록": "allCategoriesTitle",
    "이름 변경": "rename",
    "카테고리 이름 변경": "renameCategory",
    "새 카테고리 이름을 입력하세요": "enterNewCategoryName",
    "이름 중복": "duplicateName",
    "같은 이름의 카테고리가 있습니다. 다른 이름을 입력해주세요.": "duplicateNameMessage",
    "카테고리 삭제": "deleteCategory",
    "카테고리를 삭제하시겠습니까?\n카테고리에 속한 메모들은 삭제되지 않습니다.": "deleteCategoryConfirm",
    # CreateCategory
    "카테고리 생성": "createCategoryTitle",
    "카테고리 이름 입력": "categoryNamePlaceholder",
    "카테고리 이름이 비었습니다.": "emptyCategoryName",
    "카테고리 이름을 입력하여 카테고리를 추가하세요.": "emptyCategoryNameMessage",
    # PopupCard
    "카테고리 없는 메모로 복구": "recoverAsUncategorizedSingle",
    "이 메모를 복구하시겠습니까?": "recoverThisMemoConfirm",
    "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.": "recoverThisMemoMessage",
    "이 메모 삭제하기": "deleteThisMemo",
    "선택한 메모를 영구적으로 삭제하시겠습니까?": "deleteSelectedMemoConfirm",
    "메모 삭제": "deleteMemoTitle",
    "메모를 삭제하시겠습니까?": "deleteMemoConfirm",
    "제목 없음": "noTitle",
    # MemoView
    "카테고리 없는 메모들로 복구": "recoverAsUncategorizedMultiple",
    "이 메모들을 복구하시겠습니까?": "recoverTheseMemosConfirm",
    "복구된 메모들은 '카테고리 없음' 항목에서 확인할 수 있습니다.": "recoverTheseMemosMessage",
    "복구할 카테고리 선택": "selectCategoriesToRecover",
    "카테고리 일괄 추가": "batchAddCategories",
    "카테고리 일괄 해제": "batchRemoveCategories",
    "즐겨찾기에 추가": "addToFavorites",
    "즐겨찾기에 해제": "removeFromFavorites",
    "%d개의 메모 선택됨": "memosSelectedFormat",
    "즐겨찾기한 메모": "favoriteMemos",
    "전체 메모 목록": "allMemosTitle",
    "휴지통": "trash",
    "선택한 메모들을 영구적으로 삭제하시겠습니까?": "deleteSelectedMemosConfirm",
    "선택된 메모 삭제": "deleteSelectedMemos",
    "선택한 메모들을 모두 삭제하시겠습니까?": "deleteSelectedMemosMessage",
    "카테고리 이름을 비울 수 없습니다.": "categoryNameCannotBeEmpty",
    # CategorySelection
    "카테고리 선택하기": "selectCategoryTitle",
    "%d개의 카테고리 선택됨": "categoriesSelectedFormat",
    # MemoDetail
    "메모를 입력하세요.": "writeMemoPlaceholder",
    "메모 내용이 없습니다.": "memoIsEmpty",
    "메모 작성 취소": "cancelMemoCreation",
    "메모 작성을 취소하시겠습니까?": "cancelMemoCreationConfirm",
    "계속 작성": "continueWriting",
    "메모 추가하기": "addMemo",
    "이미지 한도 초과": "imageLimitExceeded",
    "메모당 이미지 저장은 최대 10개까지 가능합니다.": "imageLimitMessage",
    # Settings
    "테마 색": "themeColor",
    "날짜 표시 형식": "dateFormat",
    "시간 표시 형식": "timeFormat",
    "표시 순서": "displayOrder",
    "다크 모드": "darkMode",
    "총 메모 수": "totalMemos",
    "총 카테고리 수": "totalCategories",
    "휴지통 비우기": "emptyTrash",
    "개발자 이메일": "contactDeveloper",
    "별점/리뷰 남기기": "rateApp",
    "버전 정보": "version",
    "Settings_Placeholder_text": "placeholderText",
    "휴지통에 들어간 메모는 삭제된 지 2주가 지나면 영구적으로 삭제됩니다.": "trashRetentionMessage",
    "휴지통의 모든 메모가 삭제됩니다.\n이 동작은 취소할 수 없습니다.": "emptyTrashConfirm",
    "테마 색 선택": "selectThemeColor",
    "메모 순서 표시": "memoSortingTitle",
    "메모 정렬 기준": "memoSortingCriteria",
    "라이트 모드": "lightMode",
    "시스템 모드": "systemMode",
    "수정 시간": "modificationTime",
    "만든 시간": "creationTime",
    "오름차순": "ascending",
    "내림차순": "descending",
    "SettingsVC/수정 시간": "modificationLabel",
    "SettingsVC/만든 시간": "creationLabel",
    "SettingsVC/오름차순": "ascendingLabel",
    "SettingsVC/내림차순": "descendingLabel",
    "24시간제": "format24h",
    "12시간제": "format12h",
    # ThemeColor
    "Black/White": "blackWhite",
    "Brown": "brown",
    "Red": "red",
    "Orange": "orange",
    "Yellow": "yellow",
    "Green": "green",
    "Skyblue": "skyblue",
    "Blue": "blue",
    "Purple": "purple",
    "Black": "black",
    # Common
    "취소": "cancel",
    "확인": "ok",
    "저장": "save",
    "삭제": "delete",
    "완료": "done",
    "추가": "add",
    "해제": "remove",
    "선택": "select",
    "편집 모드": "editingMode",
    "복구": "recover",
    "알림": "alert",
    "이 동작은 취소할 수 없습니다.": "actionCannotBeUndone",
}


def main():
    with open(XCSTRINGS, 'r', encoding='utf-8') as f:
        data = json.load(f)

    keys_in_xcstrings = set(data['strings'].keys())
    keys_in_groups = {k for keys in GROUPS.values() for k in keys}

    missing_in_groups = keys_in_xcstrings - keys_in_groups
    extra_in_groups = keys_in_groups - keys_in_xcstrings
    if missing_in_groups or extra_in_groups:
        if missing_in_groups:
            print("Missing in GROUPS:", missing_in_groups)
        if extra_in_groups:
            print("Extra in GROUPS:", extra_in_groups)
        raise SystemExit(1)

    keys_in_idents = set(IDENTIFIERS.keys())
    if keys_in_idents != keys_in_xcstrings:
        diff1 = keys_in_xcstrings - keys_in_idents
        diff2 = keys_in_idents - keys_in_xcstrings
        if diff1:
            print("Missing IDENTIFIERS:", diff1)
        if diff2:
            print("Extra IDENTIFIERS:", diff2)
        raise SystemExit(1)

    # Check identifier uniqueness within each group
    for group, keys in GROUPS.items():
        idents = [IDENTIFIERS[k] for k in keys]
        if len(idents) != len(set(idents)):
            from collections import Counter
            counts = Counter(idents)
            dupes = {k: v for k, v in counts.items() if v > 1}
            print(f"Duplicate idents in group {group}: {dupes}")
            raise SystemExit(1)

    # Build flat key→ident map
    flat_mapping = {}  # key → "Group.ident"
    for group, keys in GROUPS.items():
        for k in keys:
            flat_mapping[k] = f"{group}.{IDENTIFIERS[k]}"

    # Save mapping
    with open(MAPPING_JSON, 'w', encoding='utf-8') as f:
        json.dump(flat_mapping, f, ensure_ascii=False, indent=2)

    # Generate Swift file
    lines = [
        "import Foundation",
        "",
        "/// Type-safe wrapper around Localizable.xcstrings.",
        "/// Use `L10n.<group>.<name>` instead of bare `\"...\".localized()` for compile-time safety.",
        "enum L10n {",
    ]
    for group in GROUPS:
        lines.append(f"    enum {group} {{")
        for key in GROUPS[group]:
            ident = IDENTIFIERS[key]
            # Swift string literal escape
            literal = (
                key.replace('\\', '\\\\')
                   .replace('"', '\\"')
                   .replace('\n', '\\n')
                   .replace('\t', '\\t')
            )
            lines.append(f'        static let {ident} = "{literal}".localized()')
        lines.append("    }")
        lines.append("")
    lines.append("}")
    lines.append("")

    os.makedirs(os.path.dirname(OUTPUT_SWIFT), exist_ok=True)
    with open(OUTPUT_SWIFT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print(f"Generated {OUTPUT_SWIFT}")
    print(f"Wrote {MAPPING_JSON}")
    print(f"Total: {len(flat_mapping)} keys across {len(GROUPS)} groups")


if __name__ == '__main__':
    main()
