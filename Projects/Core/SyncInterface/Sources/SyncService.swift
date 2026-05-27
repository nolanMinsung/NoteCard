//
//  SyncService.swift
//  NoteCard
//

import Combine
import Foundation

/// Firestore 기반 동기화 서비스의 추상화.
///
/// 구현체는 별도 모듈(SyncImpl)에 두고 App composition root에서 인스턴스를 만들어 의존 주입한다.
/// 본 인터페이스는 lifecycle 제어와 상태 노출만 노출하고, 실제 push/pull 책임은 구현체 내부의
/// listener·writer가 가짐(외부에서 직접 호출하지 않음).
public protocol SyncService: AnyObject, Sendable {

    /// 현재 동기화 상태. UI 즉시 표시용 동기 접근자.
    var currentStatus: SyncStatus { get }

    /// 동기화 상태 스트림. 구독 시 현재 값을 즉시 1회 발행해야 함(구현체 책임).
    var statusPublisher: AnyPublisher<SyncStatus, Never> { get }

    /// 동기화 시작. 인증된 사용자가 없으면 `.disconnected` 유지.
    /// 인증 상태 변경에 따라 자동으로 호출될 수도 있고, 명시적으로 호출해도 무관(idempotent).
    func start() async

    /// 동기화 중지. listener를 해제하고 `.disconnected` 상태로 전이.
    /// 로컬 Core Data는 그대로 유지.
    func stop() async
}
