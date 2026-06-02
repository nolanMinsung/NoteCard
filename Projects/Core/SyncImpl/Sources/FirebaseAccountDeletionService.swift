//
//  FirebaseAccountDeletionService.swift
//  NoteCard
//

import Domain
import Foundation
import SyncInterface

/// Repository 추상화를 통해 데이터 정리를 수행하는 `AccountDeletionService` 구현.
///
/// 순서: reauth → 데이터 삭제 → Auth user 삭제. reauth 를 가장 먼저 두는 이유는
/// (1) 사용자가 Apple 시트를 취소했을 때 아무것도 지워지지 않은 깨끗한 상태로 종료되고
/// (2) reauth 후 token 이 신선하므로 마지막 `user.delete()` 가 `requiresRecentLogin` 없이 통과하기 때문.
///
/// 데이터 삭제는 기존 Repository 메서드를 그대로 사용 — 호출 시점 활성 impl (보통 Firestore)
/// 의 `deleteMemo` / `deleteImage` / `deleteCategory` 가 각각의 클라우드 / Storage 부수효과를 책임진다.
public final class FirebaseAccountDeletionService: AccountDeletionService, @unchecked Sendable {

    private let authService: AuthService
    private let accountSentinelService: AccountSentinelService
    private let memoRepository: MemoRepository
    private let categoryRepository: CategoryRepository
    private let imageRepository: ImageRepository

    public init(
        authService: AuthService,
        accountSentinelService: AccountSentinelService,
        memoRepository: MemoRepository,
        categoryRepository: CategoryRepository,
        imageRepository: ImageRepository
    ) {
        self.authService = authService
        self.accountSentinelService = accountSentinelService
        self.memoRepository = memoRepository
        self.categoryRepository = categoryRepository
        self.imageRepository = imageRepository
    }

    public func deleteAccountAndAllData() async throws {
        // 1. 파괴적 작업 전에 reauth 먼저 — Apple sign-in 시트가 즉시 뜸. 사용자가 여기서 취소하면
        //    `AuthError.cancelled` 가 던져지고 데이터·계정 모두 그대로 보존.
        _ = try await authService.signInWithApple()

        // 2. sentinel doc 삭제 — 다른 기기의 listener 가 .removed 받자마자 signOut.
        //    본 기기 listener 는 service 내부에서 detach 되어 self-trigger 방지됨.
        try await accountSentinelService.deleteSentinel()

        // 3. 데이터 삭제. token 신선해서 Firestore 접근 정상.
        try await deleteAllUserData()

        // 4. Auth user 삭제. 방금 reauth 했으므로 requiresRecentLogin 발생하지 않음.
        try await authService.deleteAccount()
    }

    /// 메모 / 이미지 / 카테고리를 enumerate 해 모두 삭제. 개별 실패는 다음 항목 진행을 막지 않음 —
    /// 결과적으로 클라우드에 남은 게 있더라도 호출자가 다시 시도하면 됨.
    private func deleteAllUserData() async throws {
        let activeMemos = (try? await memoRepository.getAllMemos()) ?? []
        let trashedMemos = (try? await memoRepository.getAllMemosInTrash()) ?? []

        for memo in activeMemos + trashedMemos {
            let images = (try? await imageRepository.getAllImageInfo(for: memo)) ?? []
            for image in images {
                try? await imageRepository.deleteImage(image)
            }
            try? await memoRepository.deleteMemo(memo)
        }

        let allCategories = (try? await categoryRepository.getAllCategories(
            inOrderOf: .modificationDate, isAscending: false
        )) ?? []
        for category in allCategories {
            try? await categoryRepository.deleteCategory(category)
        }
    }
}
