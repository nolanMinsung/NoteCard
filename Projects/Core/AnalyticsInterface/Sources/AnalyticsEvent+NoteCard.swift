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

    // MARK: - Sign-in funnel

    /// Apple Sign-in 을 시도한 진입 화면.
    public enum SignInSource: String {
        case loginScreen = "login_screen"
        case accountDetail = "account_detail"
    }

    /// Sign-in 시도의 최종 결과.
    public enum SignInOutcome: String {
        case success
        /// Apple 시트에서 사용자가 취소.
        case cancelled
        /// Apple 또는 Firebase Auth 단계에서 실패 (`AuthError`).
        case authError = "auth_error"
        /// 인증은 끝났으나 readiness gate 가 timeout.
        case readinessTimeout = "readiness_timeout"
        case unknownError = "unknown_error"
    }

    /// 사용자가 Apple Sign-in 버튼을 탭한 시점.
    public static func signInStarted(source: SignInSource) -> AnalyticsEvent {
        AnalyticsEvent(name: "sign_in_started", properties: ["source": source.rawValue])
    }

    /// Sign-in 흐름이 끝났을 때 (성공·취소·각종 실패 포함).
    public static func signInOutcome(
        source: SignInSource,
        outcome: SignInOutcome,
        durationMs: Int
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "sign_in_outcome",
            properties: [
                "source": source.rawValue,
                "outcome": outcome.rawValue,
                "duration_ms": String(durationMs),
            ]
        )
    }

    /// 로그인 화면에서 사용자가 "그냥 사용" 을 확정한 시점.
    public static func signInSkipped() -> AnalyticsEvent {
        AnalyticsEvent(name: "sign_in_skipped")
    }

    // MARK: - Sync retry funnel

    /// AccountDetail 의 "동기화 재시도" 버튼 탭 결과.
    public enum SyncRetryOutcome: String {
        case success
        case readinessTimeout = "readiness_timeout"
        case unknownError = "unknown_error"
    }

    /// 사용자가 AccountDetail 의 "동기화 재시도" 버튼을 탭한 시점.
    public static func syncRetryTapped() -> AnalyticsEvent {
        AnalyticsEvent(name: "sync_retry_tapped")
    }

    /// 동기화 재시도 흐름이 끝났을 때.
    public static func syncRetryOutcome(outcome: SyncRetryOutcome, durationMs: Int) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "sync_retry_outcome",
            properties: [
                "outcome": outcome.rawValue,
                "duration_ms": String(durationMs),
            ]
        )
    }

    // MARK: - 익명 데이터 통계

    /// 익명 사용자의 데이터 규모. sign-in 시점 또는 daily launch 시 emit.
    /// 메모 컨텐츠나 이미지 파일은 절대 수집하지 않고 카운트만.
    public static func anonymousDataStats(
        memoCount: Int,
        trashedMemoCount: Int,
        categoryCount: Int,
        imageCount: Int
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "anonymous_data_stats",
            properties: [
                "memo_count": String(memoCount),
                "trashed_memo_count": String(trashedMemoCount),
                "category_count": String(categoryCount),
                "image_count": String(imageCount),
            ]
        )
    }
}
