//
//  FirestoreErrorMapper.swift
//  NoteCard
//

import FirebaseFirestore
import Foundation
import SyncInterface

/// Firestore SDK가 던지는 저수준 에러를 도메인 에러(`SyncError`)로 변환한다.
/// FirebaseFirestore 의존을 이 한 곳에 가둬, `FirestoreSyncService`는 SDK를 직접 import하지 않는다.
enum FirestoreErrorMapper {

    static func syncError(from error: Error) -> SyncError {
        let nsError = error as NSError
        guard nsError.domain == FirestoreErrorDomain,
              let code = FirestoreErrorCode.Code(rawValue: nsError.code) else {
            return .unknown(error)
        }
        switch code {
        case .unavailable:       return .network
        case .permissionDenied:  return .permissionDenied
        case .resourceExhausted: return .quotaExceeded
        case .unauthenticated:   return .unauthenticated
        default:                 return .unknown(error)
        }
    }
}
