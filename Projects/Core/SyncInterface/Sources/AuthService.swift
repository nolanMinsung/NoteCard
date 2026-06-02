//
//  AuthService.swift
//  NoteCard
//

import Combine
import Foundation
import Shared

/// 외부 인증 SDK(Firebase Auth) 통합 지점 추상화.
/// 구현체는 별도 모듈(SyncImpl)에 두고, App composition root에서만 인스턴스를 만들어 의존 주입한다.
public protocol AuthService: AnyObject, Sendable {

    /// 현재 로그인된 사용자. nil이면 로그아웃 상태.
    var currentUser: AuthUser? { get }

    /// 인증 상태 변경 스트림. 로그인·로그아웃 모두 반영.
    var authStatePublisher: AnyPublisher<AuthUser?, Never> { get }

    /// Sign in with Apple로 로그인. 시스템 시트를 띄우고 완료 시 AuthUser를 반환.
    func signInWithApple() async throws -> AuthUser

    /// 로그아웃. 클라우드 데이터는 유지되고 이 기기의 동기화만 멈춤.
    func signOut() async throws

    /// 계정 및 모든 클라우드 데이터를 삭제 (PIPA 권리 행사).
    func deleteAccount() async throws
}

/// 인증된 사용자 정보. 동기화 사용자 식별에 사용.
public struct AuthUser: Sendable, Equatable {
    public let id: String        // Firebase UID
    public let displayName: String?
    public let email: String?

    public init(id: String, displayName: String?, email: String?) {
        self.id = id
        self.displayName = displayName
        self.email = email
    }
}

/// 인증 관련 에러.
///
/// `errorDescription`은 사용자에게 직접 보여줘도 무방한 친화적 문구(`L10n.Sync.Auth.*`)를 반환.
/// 내부 진단·로깅 용도는 case 자체(예: `.missingFirebase`)나 연관된 `unknown(Error)`을 직접 참조.
public enum AuthError: LocalizedError {
    case cancelled
    case invalidCredential
    case missingFirebase
    case requiresRecentLogin
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .cancelled:           return L10n.Sync.Auth.cancelled
        case .invalidCredential:   return L10n.Sync.Auth.invalidCredential
        case .missingFirebase:     return L10n.Sync.Auth.unavailable
        case .requiresRecentLogin: return L10n.Sync.Auth.requiresRecentLogin
        case .unknown:             return L10n.Sync.Auth.unknown
        }
    }
}
