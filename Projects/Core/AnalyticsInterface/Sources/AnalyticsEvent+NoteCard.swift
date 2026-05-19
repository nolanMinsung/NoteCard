/// NoteCard에서 발생하는 분석 이벤트 카탈로그.
///
/// 이벤트 이름·파라미터를 한곳에 모아, 호출부가 여러 곳이어도 정의는 단일
/// 출처로 유지한다. 새 이벤트는 여기에 팩토리 메서드로 추가한다.
///
/// ⚠️ 파라미터에는 사용자 데이터(메모 제목·본문, 카테고리 이름, 검색어 등)를
/// 절대 담지 않는다 — 카운트·불리언·enum 같은 메타데이터만 전송한다.
extension AnalyticsEvent {

    /// `screen_view` 이벤트의 화면 이름.
    public enum Screen: String {
        case home
        case memoList = "memo_list"
        case memoCard = "memo_card"
        case memoEditor = "memo_editor"
        case search
        case settings
    }

    public static func screenView(_ screen: Screen) -> AnalyticsEvent {
        AnalyticsEvent(name: "screen_view", properties: ["screen_name": screen.rawValue])
    }

    public static func memoCreated(imageCount: Int, categoryCount: Int, hasTitle: Bool) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "memo_created",
            properties: memoProperties(imageCount: imageCount, categoryCount: categoryCount, hasTitle: hasTitle)
        )
    }

    public static func memoEdited(imageCount: Int, categoryCount: Int, hasTitle: Bool) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "memo_edited",
            properties: memoProperties(imageCount: imageCount, categoryCount: categoryCount, hasTitle: hasTitle)
        )
    }

    /// 메모 저장 실패. `mode`는 `"making"` 또는 `"editing"`.
    public static func memoSaveFailed(mode: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "memo_save_failed", properties: ["mode": mode])
    }

    public static func memoMovedToTrash(count: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "memo_moved_to_trash", properties: ["count": String(count)])
    }

    public static func memoDeleted(count: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "memo_deleted", properties: ["count": String(count)])
    }

    private static func memoProperties(
        imageCount: Int,
        categoryCount: Int,
        hasTitle: Bool
    ) -> [String: String] {
        [
            "image_count": String(imageCount),
            "category_count": String(categoryCount),
            "has_title": String(hasTitle),
        ]
    }
}
