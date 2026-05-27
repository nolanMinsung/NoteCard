//
//  SyncError.swift
//  NoteCard
//

import Foundation
import Shared

/// 동기화 작업 중 발생할 수 있는 에러.
///
/// `errorDescription`은 사용자에게 직접 보여줘도 무방한 친화적 문구(`L10n.Sync.Error.*`)를 반환.
/// 내부 진단·로깅 용도는 case 자체나 연관된 `unknown(Error)`을 직접 참조.
public enum SyncError: LocalizedError {
    /// 오프라인 또는 네트워크 끊김.
    case network
    /// Firestore Security Rules에서 거부. 보통 토큰이 stale하거나 다른 사용자의 데이터에 접근한 경우.
    case permissionDenied
    /// Firebase 프로젝트의 quota 초과.
    case quotaExceeded
    /// 인증이 끊긴 상태에서 동기화가 호출됨. 로그아웃 직후 listener 정리 race 등.
    case unauthenticated
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .network:           return L10n.Sync.Error.network
        case .permissionDenied:  return L10n.Sync.Error.permissionDenied
        case .quotaExceeded:     return L10n.Sync.Error.quotaExceeded
        case .unauthenticated:   return L10n.Sync.Error.unauthenticated
        case .unknown:           return L10n.Sync.Error.unknown
        }
    }
}
