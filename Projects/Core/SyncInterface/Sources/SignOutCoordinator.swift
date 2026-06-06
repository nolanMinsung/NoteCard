//
//  SignOutCoordinator.swift
//  NoteCard
//

import Combine
import Foundation

public enum SignOutPhase: Equatable, Sendable {
    case idle
    case signingOut
}

/// Sign-out 흐름을 단일 지점으로 모은 코디네이터.
///
/// Auth signOut + Router 들의 익명 impl 복귀 + rootVC 교체까지의 짧은 구간 동안
/// window 레벨 차단 overlay 표시를 위한 phase 신호를 노출.
public protocol SignOutCoordinator: Sendable {
    var phasePublisher: AnyPublisher<SignOutPhase, Never> { get }
    func performSignOut() async throws
}
