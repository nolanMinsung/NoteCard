//
//  AuthServiceUserIDProvider.swift
//  NoteCard
//

import Combine
import Domain
import Foundation
import SyncInterface

/// `AuthService`의 인증 상태를 Data 레이어가 쓰는 `CurrentUserIDProvider` 형태로 노출하는 어댑터.
/// Data ↔ Sync 간 직접 의존을 끊고 composition root에서만 연결한다.
public final class AuthServiceUserIDProvider: CurrentUserIDProvider, @unchecked Sendable {

    private let subject: CurrentValueSubject<String?, Never>
    private var cancellable: AnyCancellable?

    public init(authService: AuthService) {
        self.subject = CurrentValueSubject(authService.currentUser?.id)
        self.cancellable = authService.authStatePublisher
            .map { $0?.id }
            .sink { [weak self] userID in
                self?.subject.send(userID)
            }
    }

    public var currentUserID: String? { subject.value }

    public var currentUserIDPublisher: AnyPublisher<String?, Never> {
        subject.eraseToAnyPublisher()
    }
}
