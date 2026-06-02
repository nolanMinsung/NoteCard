//
//  FirebaseAuthService.swift
//  NoteCard
//

import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import Foundation
import SyncInterface
import UIKit

/// Firebase Auth 기반 `AuthService` 구현. Sign in with Apple을 단일 인증 수단으로 사용.
///
/// 동작 개요:
/// - `Auth.auth().addStateDidChangeListener`로 인증 상태 변경을 구독해 `CurrentValueSubject`에 흘림.
/// - Sign-in 흐름은 `ASAuthorizationController`의 delegate 패턴을 `CheckedContinuation`으로 async 래핑.
/// - Apple `fullName`은 첫 sign-in에만 제공되므로 그때 Firebase `displayName`으로 영구 저장.
public final class FirebaseAuthService: NSObject, AuthService, @unchecked Sendable {

    private let authStateSubject = CurrentValueSubject<AuthUser?, Never>(nil)
    private var stateHandle: AuthStateDidChangeListenerHandle?

    // ASAuthorizationController delegate 콜백을 async로 잇기 위한 상태.
    // 동시에 하나의 sign-in만 진행한다고 가정 (UI 흐름상 자연스러움).
    private var currentNonce: String?
    private var signInContinuation: CheckedContinuation<AuthUser, Error>?

    public override init() {
        super.init()
        // Firebase listener 첫 fire 가 비동기라 init 직후 currentUser 가 nil. 캐시 사용자를 미리 시드.
        if let user = Auth.auth().currentUser {
            authStateSubject.send(Self.toAuthUser(user))
        }
        attachAuthStateListener()
    }

    deinit {
        if let handle = stateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    public var currentUser: AuthUser? {
        authStateSubject.value
    }

    public var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    public func signInWithApple() async throws -> AuthUser {
        try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation

            let nonce = Self.randomNonceString()
            self.currentNonce = nonce

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    public func signOut() async throws {
        try Auth.auth().signOut()
    }

    public func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.invalidCredential
        }
        do {
            try await user.delete()
        } catch {
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Private

    private func attachAuthStateListener() {
        stateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            let newValue = user.map(Self.toAuthUser)
            guard self.authStateSubject.value != newValue else { return }
            self.authStateSubject.send(newValue)
        }
    }

    private static func toAuthUser(_ user: User) -> AuthUser {
        AuthUser(id: user.uid, displayName: user.displayName, email: user.email)
    }

    /// Apple sign-in 보안용 random nonce 생성. (Apple 권장 패턴)
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let code = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if code != errSecSuccess { fatalError("SecRandomCopyBytes failed: \(code)") }
                return random
            }
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    private func resumeSignIn(returning user: AuthUser) {
        signInContinuation?.resume(returning: user)
        signInContinuation = nil
        currentNonce = nil
    }

    private func resumeSignIn(throwing error: Error) {
        signInContinuation?.resume(throwing: error)
        signInContinuation = nil
        currentNonce = nil
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension FirebaseAuthService: ASAuthorizationControllerDelegate {

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = appleIDCredential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            resumeSignIn(throwing: AuthError.invalidCredential)
            return
        }

        // fullName은 첫 sign-in에만 옴. 이후 sign-in에선 nil → Firebase displayName에 영구 저장.
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self else { return }
            if let error {
                self.resumeSignIn(throwing: error)
                return
            }
            guard let user = authResult?.user else {
                self.resumeSignIn(throwing: AuthError.invalidCredential)
                return
            }
            self.persistDisplayNameIfNeeded(appleCredential: appleIDCredential, user: user) {
                self.resumeSignIn(returning: Self.toAuthUser(Auth.auth().currentUser ?? user))
            }
        }
    }

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithError error: Error) {
        if let asError = error as? ASAuthorizationError, asError.code == .canceled {
            resumeSignIn(throwing: AuthError.cancelled)
        } else {
            resumeSignIn(throwing: AuthError.unknown(error))
        }
    }

    private func persistDisplayNameIfNeeded(appleCredential: ASAuthorizationAppleIDCredential,
                                            user: User,
                                            completion: @escaping () -> Void) {
        guard
            user.displayName == nil,
            let nameComponents = appleCredential.fullName
        else {
            completion()
            return
        }
        let fullName = PersonNameComponentsFormatter().string(from: nameComponents)
        guard !fullName.isEmpty else {
            completion()
            return
        }
        let change = user.createProfileChangeRequest()
        change.displayName = fullName
        change.commitChanges { _ in completion() }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension FirebaseAuthService: ASAuthorizationControllerPresentationContextProviding {

    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
            .first ?? ASPresentationAnchor()
    }
}
