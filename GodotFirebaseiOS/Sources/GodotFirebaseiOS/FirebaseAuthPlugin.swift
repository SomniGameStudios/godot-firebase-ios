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
    // Public signals — match GodotFirebaseAndroid Auth API exactly
    @Signal("current_user_data") var auth_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var auth_failure: SignalWithArguments<String>
    @Signal("success") var sign_out_success: SignalWithArguments<Bool>
    @Signal("current_user_data") var link_with_google_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var link_with_google_failure: SignalWithArguments<String>
    @Signal("success") var user_deleted: SignalWithArguments<Bool>
    @Signal("current_user_data") var link_with_apple_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var link_with_apple_failure: SignalWithArguments<String>

    // Email/password signals
    @Signal("current_user_data") var create_user_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var create_user_failure: SignalWithArguments<String>
    @Signal("success") var password_reset_success: SignalWithArguments<Bool>
    @Signal("error_message") var password_reset_failure: SignalWithArguments<String>

    // Auth state listener signal
    @Signal("signed_in", "current_user_data") var auth_state_changed: SignalWithArguments<Bool, GDictionary>

    // ID token signals
    @Signal("token") var id_token_result: SignalWithArguments<String>
    @Signal("error_message") var id_token_error: SignalWithArguments<String>

    // Profile update signals
    @Signal("success") var profile_updated: SignalWithArguments<Bool>
    @Signal("error_message") var profile_update_failure: SignalWithArguments<String>

    private var appleSignInHelper: AppleSignInHelper?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Emulator

    @Callable
    func use_emulator(host: String, port: Int) {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized. Call FirebaseIOS core.initialize() first.")
            return
        }
        Auth.auth().useEmulator(withHost: host, port: port)
    }

    // MARK: - Anonymous Auth

    @Callable
    func sign_in_anonymously() {
        guard FirebaseApp.app() != nil else {
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

    // MARK: - Email/Password Auth

    @Callable
    func create_user_with_email(email: String, password: String) {
        guard FirebaseApp.app() != nil else {
            create_user_failure.emit("Firebase not initialized")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.create_user_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                guard let user = result?.user else { return }
                self.create_user_success.emit(self.userToDict(user))
            }
        }
    }

    @Callable
    func sign_in_with_email(email: String, password: String) {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
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

    @Callable
    func send_password_reset_email(email: String) {
        guard FirebaseApp.app() != nil else {
            password_reset_failure.emit("Firebase not initialized")
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.password_reset_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                self.password_reset_success.emit(true)
            }
        }
    }

    // MARK: - Google Sign-In

    @Callable
    func sign_in_with_google() {
        guard FirebaseApp.app() != nil else {
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
        guard FirebaseApp.app() != nil else {
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
        guard FirebaseApp.app() != nil else {
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
        guard FirebaseApp.app() != nil else {
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
        guard FirebaseApp.app() != nil else {
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

    // MARK: - Auth State Listener

    @Callable
    func add_auth_state_listener() {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        if authStateHandle != nil { return }
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    self.auth_state_changed.emit(true, self.userToDict(user))
                } else {
                    self.auth_state_changed.emit(false, GDictionary())
                }
            }
        }
    }

    @Callable
    func remove_auth_state_listener() {
        guard let handle = authStateHandle else { return }
        Auth.auth().removeStateDidChangeListener(handle)
        authStateHandle = nil
    }

    // MARK: - ID Token

    @Callable
    func get_id_token(forceRefresh: Bool) {
        guard FirebaseApp.app() != nil else {
            id_token_error.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            id_token_error.emit("No user signed in")
            return
        }
        user.getIDTokenForcingRefresh(forceRefresh) { [weak self] token, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.id_token_error.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                self.id_token_result.emit(token ?? "")
            }
        }
    }

    // MARK: - Profile Management

    @Callable
    func update_profile(displayName: String, photoUrl: String) {
        guard FirebaseApp.app() != nil else {
            profile_update_failure.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            profile_update_failure.emit("No user signed in")
            return
        }
        let changeRequest = user.createProfileChangeRequest()
        if !displayName.isEmpty {
            changeRequest.displayName = displayName
        }
        if !photoUrl.isEmpty {
            changeRequest.photoURL = URL(string: photoUrl)
        }
        changeRequest.commitChanges { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.profile_update_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                self.profile_updated.emit(true)
            }
        }
    }

    @Callable
    func update_password(newPassword: String) {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            auth_failure.emit("No user signed in")
            return
        }
        user.updatePassword(to: newPassword) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                self.profile_updated.emit(true)
            }
        }
    }

    @Callable
    func send_email_verification() {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            auth_failure.emit("No user signed in")
            return
        }
        user.sendEmailVerification { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                self.profile_updated.emit(true)
            }
        }
    }

    @Callable
    func reload_user() {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            auth_failure.emit("No user signed in")
            return
        }
        user.reload { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                if let refreshedUser = Auth.auth().currentUser {
                    self.auth_success.emit(self.userToDict(refreshedUser))
                } else {
                    self.auth_failure.emit("User became nil after reload")
                }
            }
        }
    }

    @Callable
    func unlink_provider(providerId: String) {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            auth_failure.emit("No user signed in")
            return
        }
        user.unlink(fromProvider: providerId) { [weak self] updatedUser, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                if let updatedUser {
                    self.auth_success.emit(self.userToDict(updatedUser))
                } else {
                    self.auth_failure.emit("User became nil after unlinking provider")
                }
            }
        }
    }

    @Callable
    func reauthenticate_with_email(email: String, password: String) {
        guard FirebaseApp.app() != nil else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        guard let user = Auth.auth().currentUser else {
            auth_failure.emit("No user signed in")
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.reauthenticate(with: credential) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    let nsError = error as NSError
                    self.auth_failure.emit("[\(nsError.code)] \(error.localizedDescription)")
                    return
                }
                if let user = result?.user {
                    self.auth_success.emit(self.userToDict(user))
                } else {
                    self.auth_failure.emit("User became nil after reauthentication")
                }
            }
        }
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
        dict[Variant("phoneNumber")] = Variant(user.phoneNumber ?? "")
        dict[Variant("isAnonymous")] = Variant(user.isAnonymous)
        dict[Variant("isEmailVerified")] = Variant(user.isEmailVerified)

        // Metadata
        let formatter = ISO8601DateFormatter()
        var metadata = GDictionary()
        if let creationDate = user.metadata.creationDate {
            metadata[Variant("creationDate")] = Variant(formatter.string(from: creationDate))
        } else {
            metadata[Variant("creationDate")] = Variant("")
        }
        if let lastSignInDate = user.metadata.lastSignInDate {
            metadata[Variant("lastSignInDate")] = Variant(formatter.string(from: lastSignInDate))
        } else {
            metadata[Variant("lastSignInDate")] = Variant("")
        }
        dict[Variant("metadata")] = Variant(metadata)

        var providers = GArray()
        for provider in user.providerData {
            var p = GDictionary()
            p[Variant("providerId")] = Variant(provider.providerID)
            p[Variant("uid")] = Variant(provider.uid)
            p[Variant("email")] = Variant(provider.email ?? "")
            p[Variant("displayName")] = Variant(provider.displayName ?? "")
            p[Variant("photoURL")] = Variant(provider.photoURL?.absoluteString ?? "")
            providers.append(Variant(p))
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
