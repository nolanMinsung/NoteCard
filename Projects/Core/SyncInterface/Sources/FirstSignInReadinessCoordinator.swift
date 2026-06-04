//
//  FirstSignInReadinessCoordinator.swift
//  NoteCard
//

import Combine
import Foundation

/// 사인인 시점부터 home 진입 가능 상태까지의 단계를 표현.
public enum SignInPhase: Equatable, Sendable {
    case idle
    case signingIn
    case uploading
    case downloading
    case ready
}

public enum SignInReadinessError: Error, Sendable {
    case timeout
}

/// 첫 사인인 후 사용자가 home 으로 진입해도 안전한 시점까지 대기.
///
/// awaitReady 는 다음 조건을 모두 만족할 때 반환:
/// - 익명 → Firestore 마이그레이션 완료 (Memo / Category / Image 메타 marker set + cleanup 완료)
/// - 사용자 데이터의 첫 server snapshot 도착 (Memo + Category listener)
///
/// phasePublisher 는 UI 가 사인인 진행 상태를 표시할 수 있도록 단계를 emit.
public protocol FirstSignInReadinessCoordinator: Sendable {
    var phasePublisher: AnyPublisher<SignInPhase, Never> { get }
    func reportSigningIn()
    func awaitReady(userID: String, timeout: TimeInterval) async throws
    func retryReady(userID: String, timeout: TimeInterval) async throws
    func reset()
}

public extension FirstSignInReadinessCoordinator {
    /// 현재 사용자에 대해 동기화가 완료됐는지 검사. cleanup 마커 set 이면 완료로 간주.
    /// AccountDetail 등 UI 가 재시도 버튼 노출 여부를 결정할 때 사용.
    func isSyncCompleted(for userID: String) -> Bool {
        UserDefaults.standard.bool(forKey: "sync.anonymousMigrationCleanup.\(userID)")
    }
}
