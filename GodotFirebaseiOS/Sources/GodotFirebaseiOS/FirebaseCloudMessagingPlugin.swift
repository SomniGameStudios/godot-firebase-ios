@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseMessaging
import UserNotifications
#if canImport(UIKit)
import UIKit
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
    private var delegateHelper: MessagingDelegateHelper?
    private var notificationDelegateHelper: NotificationDelegateHelper?

    // MARK: - Configuration

    @Callable
    func configure() {
        #if os(iOS)
        guard !isConfigured else { return }
        guard FirebaseApp.app() != nil else {
            GD.pushWarning("FirebaseCloudMessagingPlugin: FirebaseApp not configured. Call Auth.initialize() first.")
            return
        }

        delegateHelper = MessagingDelegateHelper(plugin: self)
        Messaging.messaging().delegate = delegateHelper

        notificationDelegateHelper = NotificationDelegateHelper(plugin: self)

        let previousDelegate = UNUserNotificationCenter.current().delegate
        notificationDelegateHelper?.previousDelegate = previousDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegateHelper

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        isConfigured = true
        #endif
    }

    // MARK: - Permission

    @Callable
    func request_permission(provisional: Bool) {
        #if os(iOS)
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]
        if provisional {
            options.insert(.provisional)
        }
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.permission_result.emit(granted)
            }
        }
        #endif
    }

    @Callable
    func get_permission_status() -> String {
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
    func get_token() {
        #if os(iOS)
        Messaging.messaging().token { [weak self] token, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let token {
                    self.token_received.emit(token)
                } else if let error {
                    self.token_error.emit(error.localizedDescription)
                }
            }
        }
        #endif
    }

    @Callable
    func delete_token() {
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
    func subscribe_to_topic(topic: String) {
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
    func unsubscribe_from_topic(topic: String) {
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
                            dict[Variant("_title")] = Variant(title)
                        }
                        if let body = alert["body"] as? String {
                            dict[Variant("_body")] = Variant(body)
                        }
                    } else if let alertStr = aps["alert"] as? String {
                        dict[Variant("_body")] = Variant(alertStr)
                    }
                    if let badge = aps["badge"] as? Int {
                        dict[Variant("_badge")] = Variant(badge)
                    }
                    if let sound = aps["sound"] as? String {
                        dict[Variant("_sound")] = Variant(sound)
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
