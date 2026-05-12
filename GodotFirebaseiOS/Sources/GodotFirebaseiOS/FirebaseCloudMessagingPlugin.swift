@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseMessaging
import UserNotifications
#if canImport(UIKit)
import UIKit
import ObjectiveC
#endif

// MARK: - APNs Registration Interception

#if os(iOS)
private final class APNsRegistrationInterceptor {
    private typealias DidRegisterIMP = @convention(c) (AnyObject, Selector, UIApplication, Data) -> Void
    private typealias DidFailIMP = @convention(c) (AnyObject, Selector, UIApplication, NSError) -> Void

    private static var installedClassIds = Set<ObjectIdentifier>()
    private static var originalDidRegisterImplementations: [ObjectIdentifier: IMP] = [:]
    private static var originalDidFailImplementations: [ObjectIdentifier: IMP] = [:]

    static func install() {
        guard let delegate = UIApplication.shared.delegate else {
            GD.print("FirebaseCloudMessagingPlugin: APNs interceptor skipped: UIApplication delegate is nil")
            return
        }
        guard let delegateClass = object_getClass(delegate) else {
            GD.print("FirebaseCloudMessagingPlugin: APNs interceptor skipped: could not read UIApplication delegate class")
            return
        }

        let classId = ObjectIdentifier(delegateClass)
        guard !installedClassIds.contains(classId) else { return }
        installedClassIds.insert(classId)

        installDidRegister(on: delegateClass, classId: classId)
        installDidFail(on: delegateClass, classId: classId)
        GD.print("FirebaseCloudMessagingPlugin: APNs interceptor installed on \(delegateClass)")
    }

    private static func installDidRegister(on delegateClass: AnyClass, classId: ObjectIdentifier) {
        let selector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let block: @convention(block) (AnyObject, UIApplication, Data) -> Void = { delegate, application, deviceToken in
            GD.print("FirebaseCloudMessagingPlugin: intercepted APNs device token; bytes=\(deviceToken.count)")
            NotificationCenter.default.post(
                name: NSNotification.Name("GodotDidRegisterForRemoteNotificationsWithDeviceToken"),
                object: nil,
                userInfo: ["deviceToken": deviceToken]
            )

            if let originalImplementation = originalDidRegisterImplementations[classId] {
                let original = unsafeBitCast(originalImplementation, to: DidRegisterIMP.self)
                original(delegate, selector, application, deviceToken)
            }
        }

        let newImplementation = imp_implementationWithBlock(block)
        if let method = class_getInstanceMethod(delegateClass, selector) {
            originalDidRegisterImplementations[classId] = method_setImplementation(method, newImplementation)
        } else {
            class_addMethod(delegateClass, selector, newImplementation, "v@:@@")
        }
    }

    private static func installDidFail(on delegateClass: AnyClass, classId: ObjectIdentifier) {
        let selector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        let block: @convention(block) (AnyObject, UIApplication, NSError) -> Void = { delegate, application, error in
            GD.print("FirebaseCloudMessagingPlugin: intercepted APNs registration failure: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: NSNotification.Name("GodotDidFailToRegisterForRemoteNotifications"),
                object: nil,
                userInfo: ["error": error.localizedDescription]
            )

            if let originalImplementation = originalDidFailImplementations[classId] {
                let original = unsafeBitCast(originalImplementation, to: DidFailIMP.self)
                original(delegate, selector, application, error)
            }
        }

        let newImplementation = imp_implementationWithBlock(block)
        if let method = class_getInstanceMethod(delegateClass, selector) {
            originalDidFailImplementations[classId] = method_setImplementation(method, newImplementation)
        } else {
            class_addMethod(delegateClass, selector, newImplementation, "v@:@@")
        }
    }
}
#endif

@Godot
class FirebaseCloudMessagingPlugin: RefCounted, @unchecked Sendable {
    @Signal("token") var token_received: SignalWithArguments<String>
    @Signal("message") var token_error: SignalWithArguments<String>
    @Signal("data") var notification_received: SignalWithArguments<GDictionary>
    @Signal("data") var notification_opened: SignalWithArguments<GDictionary>
    @Signal("granted") var permission_result: SignalWithArguments<Bool>
    @Signal("topic") var topic_subscribe_success: SignalWithArguments<String>
    @Signal("message") var topic_subscribe_failure: SignalWithArguments<String>
    @Signal("topic") var topic_unsubscribe_success: SignalWithArguments<String>
    @Signal("message") var topic_unsubscribe_failure: SignalWithArguments<String>
    @Signal var token_delete_success: SimpleSignal
    @Signal("message") var token_delete_failure: SignalWithArguments<String>


    private var isConfigured = false
    private var pendingTokenRequest = false
    private var delegateHelper: MessagingDelegateHelper?
    private var notificationDelegateHelper: NotificationDelegateHelper?

    private func log(_ message: String) {
        GD.print("FirebaseCloudMessagingPlugin: \(message)")
    }

    private func logTokenState(_ context: String) {
        #if os(iOS)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorizationStatus: String
            switch settings.authorizationStatus {
            case .notDetermined: authorizationStatus = "not_determined"
            case .denied: authorizationStatus = "denied"
            case .authorized: authorizationStatus = "authorized"
            case .provisional: authorizationStatus = "provisional"
            case .ephemeral: authorizationStatus = "ephemeral"
            @unknown default: authorizationStatus = "unknown"
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let apnsTokenState = Messaging.messaging().apnsToken == nil ? "missing" : "present"
                let remoteRegistrationState = UIApplication.shared.isRegisteredForRemoteNotifications ? "registered" : "not_registered"
                self.log("\(context): notification_permission=\(authorizationStatus), remote_notifications=\(remoteRegistrationState), firebase_apns_token=\(apnsTokenState)")
            }
        }
        #endif
    }

    // MARK: - Configuration

    @Callable
    func messagingConfigure() {
        #if os(iOS)
        guard !isConfigured else {
            log("configure skipped: already configured")
            return
        }
        guard FirebaseApp.app() != nil else {
            GD.pushWarning("FirebaseCloudMessagingPlugin: FirebaseApp not configured. Call Auth.initialize() first.")
            return
        }

        log("configure started")
        delegateHelper = MessagingDelegateHelper(plugin: self)
        Messaging.messaging().delegate = delegateHelper
        log("Messaging delegate attached")

        notificationDelegateHelper = NotificationDelegateHelper(plugin: self)

        let previousDelegate = UNUserNotificationCenter.current().delegate
        notificationDelegateHelper?.previousDelegate = previousDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegateHelper
        log("UNUserNotificationCenter delegate attached; previous delegate=\(String(describing: previousDelegate))")

        NotificationCenter.default.addObserver(forName: NSNotification.Name("GodotDidRegisterForRemoteNotificationsWithDeviceToken"), object: nil, queue: .main) { [weak self] notification in
            guard let self = self, let deviceToken = notification.userInfo?["deviceToken"] as? Data else { return }
            self.log("received Godot APNs device-token notification; bytes=\(deviceToken.count)")
            Messaging.messaging().apnsToken = deviceToken
            self.logTokenState("after manual APNs token mapping")
            self.fetchFCMToken(reason: "APNs handover")
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("GodotDidFailToRegisterForRemoteNotifications"), object: nil, queue: .main) { [weak self] notification in
            guard let self else { return }
            let message = notification.userInfo?["error"] as? String ?? "unknown error"
            self.log("APNs registration failed: \(message)")
        }

        DispatchQueue.main.async {
            APNsRegistrationInterceptor.install()
            self.log("calling UIApplication.registerForRemoteNotifications()")
            UIApplication.shared.registerForRemoteNotifications()
        }

        logTokenState("after configure")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.logTokenState("2s after configure")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            self?.logTokenState("6s after configure")
        }

        isConfigured = true
        #endif
    }

    // MARK: - Permission

    @Callable
    func messagingRequestPermission(provisional: Bool) {
        #if os(iOS)
        log("requesting notification permission; provisional=\(provisional)")
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]
        if provisional {
            options.insert(.provisional)
        }
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.log("notification permission result=\(granted)")
                self.log("calling UIApplication.registerForRemoteNotifications() after permission result")
                UIApplication.shared.registerForRemoteNotifications()
                self.logTokenState("after permission result")
                self.permission_result.emit(granted)
            }
        }
        #endif
    }

    @Callable
    func messagingGetPermissionStatus() -> String {
        #if os(iOS)
        var result = "unknown"
        let semaphore = DispatchSemaphore(value: 0)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined: result = "not_determined"
            case .denied: result = "denied"
            case .authorized: result = "authorized"
            case .provisional: result = "provisional"
            case .ephemeral: result = "ephemeral"
            @unknown default: result = "unknown"
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2.0)
        return result
        #else
        return "unsupported"
        #endif
    }

    // MARK: - Token

    @Callable
    func messagingGetToken() {
        #if os(iOS)
        if Messaging.messaging().apnsToken == nil {
            pendingTokenRequest = true
            log("FCM token request delayed: Firebase APNs token is missing")
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            logTokenState("delayed FCM token request")
            return
        }
        fetchFCMToken(reason: "manual request")
        #endif
    }

    private func fetchFCMToken(reason: String) {
        #if os(iOS)
        pendingTokenRequest = false
        log("requesting FCM token; reason=\(reason)")
        logTokenState("before FCM token request")
        Messaging.messaging().token { [weak self] token, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let token {
                    self.log("FCM token request succeeded; length=\(token.count)")
                    self.token_received.emit(token)
                } else if let error {
                    self.log("FCM token request failed: \(error.localizedDescription)")
                    self.token_error.emit(error.localizedDescription)
                } else {
                    self.log("FCM token request returned no token and no error")
                }
            }
        }
        #endif
    }

    @Callable
    func messagingDeleteToken() {
        #if os(iOS)
        Messaging.messaging().deleteToken { [weak self] error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let error {
                    self.token_delete_failure.emit(error.localizedDescription)
                } else {
                    self.token_delete_success.emit()
                }
            }
        }
        #endif
    }

    // MARK: - Topics

    @Callable
    func messagingSubscribeToTopic(topic: String) {
        #if os(iOS)
        Messaging.messaging().subscribe(toTopic: topic) { [weak self] error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let error {
                    self.topic_subscribe_failure.emit("[\(topic)] \(error.localizedDescription)")
                } else {
                    self.topic_subscribe_success.emit(topic)
                }
            }
        }
        #endif
    }

    @Callable
    func messagingUnsubscribeFromTopic(topic: String) {
        #if os(iOS)
        Messaging.messaging().unsubscribe(fromTopic: topic) { [weak self] error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let error {
                    self.topic_unsubscribe_failure.emit("[\(topic)] \(error.localizedDescription)")
                } else {
                    self.topic_unsubscribe_success.emit(topic)
                }
            }
        }
        #endif
    }

    // MARK: - Payload Extraction

    fileprivate func extractPayload(_ userInfo: [AnyHashable: Any]) -> GDictionary {
        var dict = GDictionary()
        for (key, value) in userInfo {
            guard let keyStr = key as? String else { continue }
            if keyStr == "aps" {
                if let aps = value as? [String: Any] {
                    if let alert = aps["alert"] as? [String: Any] {
                        if let title = alert["title"] as? String {
                            dict[Variant("title")] = Variant(title)
                        }
                        if let body = alert["body"] as? String {
                            dict[Variant("body")] = Variant(body)
                        }
                    } else if let alertStr = aps["alert"] as? String {
                        dict[Variant("body")] = Variant(alertStr)
                    }
                    if let badge = aps["badge"] as? Int {
                        dict[Variant("badge")] = Variant(badge)
                    }
                    if let sound = aps["sound"] as? String {
                        dict[Variant("sound")] = Variant(sound)
                    }
                }
                continue
            }
            if keyStr.hasPrefix("google.") || keyStr.hasPrefix("gcm.") { continue }
            if let strVal = value as? String {
                dict[Variant(keyStr)] = Variant(strVal)
            } else if let numVal = value as? NSNumber {
                dict[Variant(keyStr)] = Variant(numVal.stringValue)
            }
        }
        return dict
    }
}

// MARK: - Messaging Delegate

#if os(iOS)
class MessagingDelegateHelper: NSObject, MessagingDelegate {
    private weak var plugin: FirebaseCloudMessagingPlugin?

    init(plugin: FirebaseCloudMessagingPlugin) {
        self.plugin = plugin
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let plugin, let token = fcmToken else { return }
        DispatchQueue.main.async {
            plugin.token_received.emit(token)
        }
    }
}
#endif

// MARK: - Notification Delegate (Foreground + Tap)

#if os(iOS)
class NotificationDelegateHelper: NSObject, UNUserNotificationCenterDelegate {
    private weak var plugin: FirebaseCloudMessagingPlugin?
    weak var previousDelegate: UNUserNotificationCenterDelegate?

    init(plugin: FirebaseCloudMessagingPlugin) {
        self.plugin = plugin
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)

        if let plugin {
            let payload = plugin.extractPayload(userInfo)
            DispatchQueue.main.async {
                plugin.notification_received.emit(payload)
            }
        }

        if let prev = previousDelegate,
           prev.responds(to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))) {
            prev.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let plugin {
            let payload = plugin.extractPayload(userInfo)
            DispatchQueue.main.async {
                plugin.notification_opened.emit(payload)
            }
        }

        if let prev = previousDelegate,
           prev.responds(to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            prev.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
}
#endif
