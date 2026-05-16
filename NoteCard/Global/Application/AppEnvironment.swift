//
//  AppEnvironment.swift
//  NoteCard
//

import Data

/// 앱 전체에서 공유되는 의존성 묶음.
///
/// 프로세스 수명 동안 단 하나만 생성되어 `AppDelegate`가 소유하고,
/// `SceneDelegate`를 거쳐 화면 계층으로 생성자 주입된다.
/// Repository 구현체는 모두 같은 `CoreDataStack` 인스턴스를 공유하므로,
/// Combine publisher 이벤트도 화면 간에 끊김 없이 전달된다.
struct AppEnvironment {

    let coreDataStack: CoreDataStack
    let memoRepository: MemoRepositoryImpl
    let categoryRepository: CategoryRepositoryImpl
    let imageRepository: ImageRepositoryImpl

    init() {
        let coreDataStack = CoreDataStack()
        self.coreDataStack = coreDataStack
        let memoRepository = MemoRepositoryImpl(stack: coreDataStack)
        self.memoRepository = memoRepository
        self.categoryRepository = CategoryRepositoryImpl(stack: coreDataStack)
        self.imageRepository = ImageRepositoryImpl(stack: coreDataStack, memoRepository: memoRepository)
    }
}
