@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseAnalytics

@Godot
class FirebaseAnalyticsPlugin: RefCounted, @unchecked Sendable {

    // MARK: - Log Events

    @Callable
    func log_event(name: String, parameters: GDictionary) {
        let swiftParams = gdDictToSwiftParams(parameters)
        Analytics.logEvent(name, parameters: swiftParams.isEmpty ? nil : swiftParams)
    }

    // MARK: - User Properties

    @Callable
    func set_user_property(value: String, name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    @Callable
    func set_user_id(id: String) {
        Analytics.setUserID(id.isEmpty ? nil : id)
    }

    // MARK: - Collection Control

    @Callable
    func set_analytics_collection_enabled(enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }

    // MARK: - Default Event Parameters

    @Callable
    func set_default_event_parameters(parameters: GDictionary) {
        let swiftParams = gdDictToSwiftParams(parameters)
        Analytics.setDefaultEventParameters(swiftParams.isEmpty ? nil : swiftParams)
    }

    // MARK: - Reset

    @Callable
    func reset_analytics_data() {
        Analytics.resetAnalyticsData()
    }

    // MARK: - App Instance ID

    @Callable
    func get_app_instance_id() -> String {
        return Analytics.appInstanceID() ?? ""
    }

    // MARK: - Consent

    @Callable
    func set_consent(adStorage: Bool, analyticsStorage: Bool) {
        Analytics.setConsent([
            .adStorage: adStorage ? .granted : .denied,
            .analyticsStorage: analyticsStorage ? .granted : .denied
        ])
    }

    // MARK: - Session Timeout

    @Callable
    func set_session_timeout(seconds: Int) {
        Analytics.setSessionTimeoutInterval(TimeInterval(seconds))
    }

    // MARK: - Helpers

    private func gdDictToSwiftParams(_ gdDict: GDictionary) -> [String: Any] {
        var result: [String: Any] = [:]
        let keys = gdDict.keys()
        for i in 0..<keys.size() {
            let keyVariant = keys[Int(i)]
            guard let keyStr = String(keyVariant) else { continue }
            guard let value = gdDict[keyVariant] else { continue }
            switch value.gtype {
            case .bool:
                result[keyStr] = Bool(value) ?? false
            case .int:
                result[keyStr] = Int(value) ?? 0
            case .float:
                result[keyStr] = Double(value) ?? 0.0
            case .string:
                result[keyStr] = String(value) ?? ""
            default:
                result[keyStr] = String(value) ?? ""
            }
        }
        return result
    }
}
