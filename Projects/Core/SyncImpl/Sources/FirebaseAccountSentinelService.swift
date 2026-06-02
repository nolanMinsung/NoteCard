//
//  FirebaseAccountSentinelService.swift
//  NoteCard
//

import Combine
import FirebaseFirestore
import Foundation
import SyncInterface

/// Firestore 기반 `AccountSentinelService` 구현.
///
/// 동작:
/// - `authStatePublisher` 구독: 사인인 → `ensureSentinel` 후 listener attach. 사인아웃 → detach.
/// - listener: sentinel 이 "존재 → 비존재" 로 전이하면 강제 `signOut()`. 초기 부재 (`ensureSentinel`
///   완료 전) 는 무시.
/// - `deleteSentinel()`: 본 기기 listener 를 먼저 detach 하고 `isLocalDeletionInProgress` 플래그를 켜서
///   self-trigger 를 막은 뒤 doc 삭제.
public final class FirebaseAccountSentinelService: AccountSentinelService, @unchecked Sendable {

    private let firestore: Firestore
    private let authService: AuthService

    private let lock = NSLock()
    private var listenerRegistration: ListenerRegistration?
    private var hasSeenSentinelExist = false
    private var isLocalDeletionInProgress = false
    private var authCancellable: AnyCancellable?

    public init(authService: AuthService, firestore: Firestore = .firestore()) {
        self.authService = authService
        self.firestore = firestore
        authCancellable = authService.authStatePublisher.sink { [weak self] user in
            self?.handleAuthChange(user: user)
        }
    }

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Path

    private func sentinelDoc(for userID: String) -> DocumentReference {
        firestore.collection("users").document(userID).collection("_meta").document("active")
    }

    // MARK: - Auth state

    private func handleAuthChange(user: AuthUser?) {
        if let user {
            Task { [weak self] in
                guard let self else { return }
                // ensureSentinel 이 끝난 뒤 listener 를 붙여, 초기 fire 가 exists=true 가 되도록 한다.
                // 그래야 그 다음 .removed (다른 기기 삭제 신호) 를 정확히 감지 가능.
                try? await self.ensureSentinel(for: user.id)
                self.startListening(userID: user.id)
            }
        } else {
            stopListening()
        }
    }

    private func ensureSentinel(for userID: String) async throws {
        try await sentinelDoc(for: userID).setData([
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    // MARK: - Listener

    private func startListening(userID: String) {
        let registration = sentinelDoc(for: userID).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("[AccountSentinel] listener error: \(error)")
                return
            }
            guard let snapshot else { return }
            self.handleSnapshot(snapshot)
        }
        lock.lock()
        listenerRegistration?.remove()
        listenerRegistration = registration
        hasSeenSentinelExist = false
        lock.unlock()
    }

    private func stopListening() {
        lock.lock()
        listenerRegistration?.remove()
        listenerRegistration = nil
        hasSeenSentinelExist = false
        lock.unlock()
    }

    private func handleSnapshot(_ snapshot: DocumentSnapshot) {
        lock.lock()
        let suppressed = isLocalDeletionInProgress
        let wasExisting = hasSeenSentinelExist
        if snapshot.exists {
            hasSeenSentinelExist = true
        } else if wasExisting {
            hasSeenSentinelExist = false
        }
        lock.unlock()

        guard !suppressed else { return }
        guard !snapshot.exists, wasExisting else { return }

        // sentinel 이 살아있던 상태에서 사라짐 → 다른 기기에서 계정 삭제됐다는 신호.
        Task { [weak self] in
            try? await self?.authService.signOut()
        }
    }

    // MARK: - Public API

    public func deleteSentinel() async throws {
        guard let userID = authService.currentUser?.id else { return }

        lock.lock()
        isLocalDeletionInProgress = true
        listenerRegistration?.remove()
        listenerRegistration = nil
        lock.unlock()

        defer {
            lock.lock()
            isLocalDeletionInProgress = false
            lock.unlock()
        }

        try await sentinelDoc(for: userID).delete()
    }
}
