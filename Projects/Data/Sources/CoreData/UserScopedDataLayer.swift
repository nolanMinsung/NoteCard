//
//  UserScopedDataLayer.swift
//  NoteCard
//

import Combine
import CoreData
import Domain
import Foundation

/// 현재 사용자에 맞는 `CoreDataStack`을 vending하는 코디네이터.
///
/// `CurrentUserIDProvider`를 구독해 사용자 변경 시 해당 사용자의 store 파일로
/// 새 `CoreDataStack`을 만들어 교체한다. 동시에 하나의 stack만 보유하고, 이전
/// stack은 ARC에 의해 deallocate된다.
///
/// 파일 경로 규약:
/// - 로그인된 사용자: `<storeDirectory>/users/<uid>/NoteCard.sqlite`
/// - 익명(미로그인): `<storeDirectory>/anonymous.sqlite`
///
/// 기본 `storeDirectory`는 앱 샌드박스의 `Application Support/`. 부모 디렉터리는 자동 생성된다.
public final class UserScopedDataLayer {

    private let userIDProvider: CurrentUserIDProvider
    private let storeDirectory: URL
    private let stackSubject: CurrentValueSubject<CoreDataStack, Never>
    private var cancellable: AnyCancellable?

    public init(userIDProvider: CurrentUserIDProvider, storeDirectory: URL? = nil) {
        self.userIDProvider = userIDProvider
        let directory = storeDirectory ?? Self.defaultStoreDirectory()
        self.storeDirectory = directory
        let initialStack = Self.makeStack(for: userIDProvider.currentUserID, in: directory)
        self.stackSubject = CurrentValueSubject(initialStack)
        attachUserIDListener()
    }

    /// 현재 사용자에 해당하는 stack.
    public var currentStack: CoreDataStack {
        stackSubject.value
    }

    /// 사용자 변경 시 새 stack을 emit. 구독 시점에 현재 stack을 즉시 emit한다.
    public var currentStackPublisher: AnyPublisher<CoreDataStack, Never> {
        stackSubject.eraseToAnyPublisher()
    }

    /// 익명(미로그인) 사용자의 store 위치. 레거시 마이그레이션 목적지 등 외부에서 경로가 필요할 때.
    public static func anonymousStoreURL() -> URL {
        storeURL(for: nil, in: defaultStoreDirectory())
    }

    // MARK: - Private

    private func attachUserIDListener() {
        // removeDuplicates가 dropFirst보다 먼저 와야 함 — 순서가 반대면 첫 값이 baseline에서 빠져 같은 ID 재emit에도 stack을 다시 만든다.
        cancellable = userIDProvider.currentUserIDPublisher
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] userID in
                guard let self else { return }
                let newStack = Self.makeStack(for: userID, in: self.storeDirectory)
                self.stackSubject.send(newStack)
            }
    }

    private static func makeStack(for userID: String?, in directory: URL) -> CoreDataStack {
        let storeURL = storeURL(for: userID, in: directory)
        let parent = storeURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        } catch {
            fatalError("UserScopedDataLayer: 부모 디렉터리 생성 실패 \(parent.path): \(error)")
        }
        return CoreDataStack(storeURL: storeURL)
    }

    private static func storeURL(for userID: String?, in directory: URL) -> URL {
        if let userID {
            return directory
                .appendingPathComponent("users")
                .appendingPathComponent(userID)
                .appendingPathComponent("NoteCard.sqlite")
        } else {
            return directory.appendingPathComponent("anonymous.sqlite")
        }
    }

    private static func defaultStoreDirectory() -> URL {
        do {
            return try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            )
        } catch {
            fatalError("UserScopedDataLayer: Application Support 디렉터리 접근 실패: \(error)")
        }
    }
}
