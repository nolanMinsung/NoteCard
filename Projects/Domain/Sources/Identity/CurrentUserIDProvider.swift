//
//  CurrentUserIDProvider.swift
//  NoteCard
//

import Combine
import Foundation

/// 현재 로그인된 사용자의 ID를 노출하는 추상화.
///
/// Auth SDK(예: Firebase Auth)와 Data 레이어 사이의 의존 방향을 끊기 위한 통로.
/// Data 레이어(저장소 분리 코디네이터 등)는 *누가 어떻게* 로그인을 처리하는지 모르고,
/// 이 프로토콜을 통해 "현재 사용자 ID" 정보만 받는다.
public protocol CurrentUserIDProvider: AnyObject, Sendable {

    /// 현재 사용자 ID. `nil`이면 로그아웃(익명) 상태.
    var currentUserID: String? { get }

    /// 사용자 ID 변경 스트림. 구독 시점에 현재 값을 즉시 emit하고,
    /// 이후 사용자 변경(로그인·로그아웃·계정 전환)마다 새 값을 emit한다. 완료 신호 없음.
    var currentUserIDPublisher: AnyPublisher<String?, Never> { get }
}

/// 인증 기능이 연결되기 전이거나, 사용자가 한 번도 로그인하지 않은 환경에서 쓰는 default 구현.
///
/// 항상 `nil`을 반환하고 publisher는 nil을 한 번 emit한 채 유지된다.
/// 실제 인증 연동은 후속 PR(Auth 인프라 적용 시점)에 별도 구현체로 교체된다.
public final class AnonymousUserIDProvider: CurrentUserIDProvider, @unchecked Sendable {

    private let subject = CurrentValueSubject<String?, Never>(nil)

    public init() {}

    public var currentUserID: String? { subject.value }

    public var currentUserIDPublisher: AnyPublisher<String?, Never> {
        subject.eraseToAnyPublisher()
    }
}
