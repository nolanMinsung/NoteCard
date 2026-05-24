//
//  NoOpAuthService.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

/// 동기화를 비활성화하는 no-op 구현.
///
/// Firebase 설정(`GoogleService-Info.plist`)이 없는 환경(CI 빌드, 미설정 등)에서
/// `SyncBootstrap`이 fallback으로 사용한다. 모든 인증 요청은 `missingFirebase` 에러로 거부.
public final class NoOpAuthService: AuthService, @unchecked Sendable {
    public init() {}

    public var currentUser: AuthUser? { nil }

    public var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    public func signInWithApple() async throws -> AuthUser {
        throw AuthError.missingFirebase
    }

    public func signOut() async throws {
        // no-op
    }

    public func deleteAccount() async throws {
        throw AuthError.missingFirebase
    }
}
