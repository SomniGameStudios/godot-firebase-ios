@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

@Godot
class FirebaseAuthPlugin: RefCounted, @unchecked Sendable {
    // iOS-internal signals (not in GodotFirebaseAndroid API — used by wrapper internally)
    @Signal var firebase_initialized: SimpleSignal
    @Signal("message") var firebase_error: SignalWithArguments<String>

    // Public signals — match GodotFirebaseAndroid Auth API exactly
    @Signal("current_user_data") var auth_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var auth_failure: SignalWithArguments<String>
    @Signal("success") var sign_out_success: SignalWithArguments<Bool>
    @Signal("current_user_data") var link_with_google_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var link_with_google_failure: SignalWithArguments<String>
    @Signal("success") var user_deleted: SignalWithArguments<Bool>
    @Signal("current_user_data") var link_with_apple_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var link_with_apple_failure: SignalWithArguments<String>

    private var isInitialized = false
    private var appleSignInHelper: AppleSignInHelper?

    // MARK: - Initialization (iOS-specific, called by wrapper internally)

    @Callable
    func initialize() {
        guard !isInitialized else { return }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            firebase_error.emit("GoogleService-Info.plist not found in app bundle. Add it to the Xcode project target.")
            return
        }
        FirebaseApp.configure(options: options)
        isInitialized = true
        firebase_initialized.emit()
    }

    @Callable
    func use_emulator(host: String, port: Int) {
        guard isInitialized else {
            firebase_error.emit("Cannot configure emulator before initialization")
            return
        }
        Auth.auth().useEmulator(withHost: host, port: port)
    }

    // MARK: - Anonymous Auth

    @Callable
    func sign_in_anonymously() {
        guard isInitialized else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        // If a user is already signed in, return their data instead of creating a new session
        if let existingUser = Auth.auth().currentUser {
            Task { @MainActor in
                self.auth_success.emit(self.userToDict(existingUser))
            }
            return
        }
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                guard let user = result?.user else { return }
                self.auth_success.emit(self.userToDict(user))
            }
        }
    }

    // MARK: - Google Sign-In

    @Callable
    func sign_in_with_google() {
        guard isInitialized else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        performGoogleSignIn { [weak self] credential, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.auth_failure.emit(error) }
                return
            }
            guard let credential else { return }
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        let nsError = error as NSError
                        self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                        return
                    }
                    guard let user = result?.user else { return }
                    self.auth_success.emit(self.userToDict(user))
                }
            }
        }
    }

    @Callable
    func link_with_google() {
        guard isInitialized else {
            link_with_google_failure.emit("Firebase not initialized")
            return
        }
        guard let currentUser = Auth.auth().currentUser else {
            link_with_google_failure.emit("No user signed in")
            return
        }
        performGoogleSignIn { [weak self] credential, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.link_with_google_failure.emit(error) }
                return
            }
            guard let credential else { return }
            currentUser.link(with: credential) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        let nsError = error as NSError
                        self.link_with_google_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                        return
                    }
                    guard let user = result?.user else { return }
                    self.link_with_google_success.emit(self.userToDict(user))
                }
            }
        }
    }

    // MARK: - Apple Sign-In

    @Callable
    func sign_in_with_apple() {
        guard isInitialized else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        performAppleSignIn { [weak self] credential, error in
            guard let self else { return }
            self.appleSignInHelper = nil
            if let error {
                Task { @MainActor in self.auth_failure.emit(error) }
                return
            }
            guard let credential else { return }
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        let nsError = error as NSError
                        self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                        return
                    }
                    guard let user = result?.user else { return }
                    self.auth_success.emit(self.userToDict(user))
                }
            }
        }
    }

    @Callable
    func link_with_apple() {
        guard isInitialized else {
            link_with_apple_failure.emit("Firebase not initialized")
            return
        }
        guard let currentUser = Auth.auth().currentUser else {
            link_with_apple_failure.emit("No user signed in")
            return
        }
        performAppleSignIn { [weak self] credential, error in
            guard let self else { return }
            self.appleSignInHelper = nil
            if let error {
                Task { @MainActor in self.link_with_apple_failure.emit(error) }
                return
            }
            guard let credential else { return }
            currentUser.link(with: credential) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        let nsError = error as NSError
                        self.link_with_apple_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                        return
                    }
                    guard let user = result?.user else { return }
                    self.link_with_apple_success.emit(self.userToDict(user))
                }
            }
        }
    }

    // MARK: - Sign Out

    @Callable
    func sign_out() {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            sign_out_success.emit(true)
        } catch {
            let nsError = error as NSError
            auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
        }
    }

    // MARK: - Delete User

    @Callable
    func delete_current_user() {
        guard isInitialized else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            auth_failure.emit("No user signed in")
            return
        }
        user.delete { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                self.user_deleted.emit(true)
            }
        }
    }

    // MARK: - User State

    @Callable func is_signed_in() -> Bool { Auth.auth().currentUser != nil }

    @Callable
    func get_current_user_data() -> GDictionary {
        guard let user = Auth.auth().currentUser else { return GDictionary() }
        return userToDict(user)
    }

    // MARK: - Private Helpers

    private func performGoogleSignIn(completion: @escaping (AuthCredential?, String?) -> Void) {
        #if os(iOS)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(nil, "Missing Firebase clientID")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        DispatchQueue.main.async {
            guard let rootVC = self.topMostViewController() else {
                completion(nil, "Could not find root view controller")
                return
            }
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
                if let error {
                    completion(nil, error.localizedDescription)
                    return
                }
                guard let user = result?.user, let idToken = user.idToken else {
                    completion(nil, "Google Sign-In failed: missing token")
                    return
                }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken.tokenString,
                    accessToken: user.accessToken.tokenString
                )
                completion(credential, nil)
            }
        }
        #else
        completion(nil, "Google Sign-In is only available on iOS")
        #endif
    }

    private func performAppleSignIn(completion: @escaping (AuthCredential?, String?) -> Void) {
        #if os(iOS)
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        DispatchQueue.main.async {
            guard let window = self.topMostViewController()?.view.window else {
                completion(nil, "Could not find presenting window for Apple Sign-In")
                return
            }
            let helper = AppleSignInHelper(window: window, rawNonce: nonce, completion: completion)
            self.appleSignInHelper = helper

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = helper
            controller.presentationContextProvider = helper
            controller.performRequests()
        }
        #else
        completion(nil, "Apple Sign-In is only available on iOS")
        #endif
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    #if os(iOS)
    @MainActor
    private func topMostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        return findTopViewController(from: root)
    }

    private func findTopViewController(from vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return findTopViewController(from: nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController {
            return findTopViewController(from: tab.selectedViewController ?? tab)
        }
        if let presented = vc.presentedViewController {
            return findTopViewController(from: presented)
        }
        return vc
    }
    #endif

    private func userToDict(_ user: FirebaseAuth.User) -> GDictionary {
        var dict = GDictionary()
        dict[Variant("uid")] = Variant(user.uid)
        dict[Variant("email")] = Variant(user.email ?? "")
        dict[Variant("displayName")] = Variant(user.displayName ?? "")
        dict[Variant("photoURL")] = Variant(user.photoURL?.absoluteString ?? "")
        dict[Variant("isAnonymous")] = Variant(user.isAnonymous)
        var providers = GArray()
        for provider in user.providerData {
            var p = GDictionary()
            p[Variant("providerId")] = Variant(provider.providerID)
            p[Variant("uid")] = Variant(provider.uid)
            p[Variant("email")] = Variant(provider.email ?? "")
            p[Variant("displayName")] = Variant(provider.displayName ?? "")
            p[Variant("photoURL")] = Variant(provider.photoURL?.absoluteString ?? "")
            providers.append(value: Variant(p))
        }
        dict[Variant("providerData")] = Variant(providers)
        return dict
    }
}

// MARK: - Apple Sign-In Delegate Helper

#if os(iOS)
class AppleSignInHelper: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let window: UIWindow
    private let rawNonce: String
    private let completion: (AuthCredential?, String?) -> Void

    init(window: UIWindow, rawNonce: String, completion: @escaping (AuthCredential?, String?) -> Void) {
        self.window = window
        self.rawNonce = rawNonce
        self.completion = completion
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            completion(nil, "Apple Sign-In failed: unable to retrieve identity token")
            return
        }
        // Use appleCredential to pass fullName — Apple only shares it on first sign-in
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: appleIDCredential.fullName
        )
        completion(credential, nil)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(nil, error.localizedDescription)
    }
}
#endif
