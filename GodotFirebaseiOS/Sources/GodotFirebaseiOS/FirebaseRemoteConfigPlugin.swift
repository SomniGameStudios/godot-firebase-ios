@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseRemoteConfig

@Godot
class FirebaseRemoteConfigPlugin: RefCounted, @unchecked Sendable {
    // Signals
    @Signal("result") var fetch_completed: SignalWithArguments<GDictionary>
    @Signal("result") var activate_completed: SignalWithArguments<GDictionary>
    @Signal("updated_keys") var config_updated: SignalWithArguments<GArray>

    private var remoteConfig: RemoteConfig?
    private var configUpdateRegistration: ConfigUpdateListenerRegistration?

    // MARK: - Setup

    @Callable
    func initialize() {
        guard FirebaseApp.app() != nil else { return }
        remoteConfig = RemoteConfig.remoteConfig()
    }

    @Callable
    func set_defaults(defaults: GDictionary) {
        guard let remoteConfig else { return }
        var swiftDefaults: [String: NSObject] = [:]
        let keys = defaults.keys()
        for i in 0..<keys.size() {
            let keyVariant = keys[Int(i)]
            guard let keyStr = String(keyVariant) else { continue }
            guard let value = defaults[keyVariant] else { continue }
            swiftDefaults[keyStr] = variantToNSObject(value)
        }
        remoteConfig.setDefaults(swiftDefaults)
    }

    @Callable
    func set_minimum_fetch_interval(seconds: Int) {
        guard let remoteConfig else { return }
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = TimeInterval(seconds)
        remoteConfig.configSettings = settings
    }

    // MARK: - Fetch & Activate

    @Callable
    func fetch() {
        guard let remoteConfig else {
            Task { @MainActor in self.fetch_completed.emit(self.buildResult(status: false, error: "RemoteConfig not initialized")) }
            return
        }
        remoteConfig.fetch { [weak self] status, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.fetch_completed.emit(self.buildResult(status: false, error: error.localizedDescription))
                    return
                }
                self.fetch_completed.emit(self.buildResult(status: status == .success))
            }
        }
    }

    @Callable
    func activate() {
        guard let remoteConfig else {
            Task { @MainActor in self.activate_completed.emit(self.buildResult(status: false, error: "RemoteConfig not initialized")) }
            return
        }
        remoteConfig.activate { [weak self] changed, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.activate_completed.emit(self.buildResult(status: false, error: error.localizedDescription))
                    return
                }
                self.activate_completed.emit(self.buildResult(status: true))
            }
        }
    }

    @Callable
    func fetch_and_activate() {
        guard let remoteConfig else {
            Task { @MainActor in self.fetch_completed.emit(self.buildResult(status: false, error: "RemoteConfig not initialized")) }
            return
        }
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.fetch_completed.emit(self.buildResult(status: false, error: error.localizedDescription))
                    return
                }
                let success = (status == .successFetchedFromRemote || status == .successUsingPreFetchedData)
                self.fetch_completed.emit(self.buildResult(status: success))
                self.activate_completed.emit(self.buildResult(status: success))
            }
        }
    }

    // MARK: - Value Getters (synchronous, read from local cache)

    @Callable
    func get_string(key: String) -> String {
        return remoteConfig?.configValue(forKey: key).stringValue ?? ""
    }

    @Callable
    func get_bool(key: String) -> Bool {
        return remoteConfig?.configValue(forKey: key).boolValue ?? false
    }

    @Callable
    func get_int(key: String) -> Int {
        return remoteConfig?.configValue(forKey: key).numberValue.intValue ?? 0
    }

    @Callable
    func get_float(key: String) -> Double {
        return remoteConfig?.configValue(forKey: key).numberValue.doubleValue ?? 0.0
    }

    @Callable
    func get_all() -> GDictionary {
        guard let remoteConfig else { return GDictionary() }
        var dict = GDictionary()
        let keys = remoteConfig.allKeys(from: .remote)
        for key in keys {
            let value = remoteConfig.configValue(forKey: key)
            dict[Variant(key)] = Variant(value.stringValue ?? "")
        }
        return dict
    }

    // MARK: - Real-time Listeners

    @Callable
    func listen_for_updates() {
        guard let remoteConfig else { return }
        if configUpdateRegistration != nil { return }
        configUpdateRegistration = remoteConfig.addOnConfigUpdateListener { [weak self] update, error in
            guard let self else { return }
            if error != nil { return }
            guard let update else { return }
            remoteConfig.activate { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in
                    var gdArray = GArray()
                    for key in update.updatedKeys {
                        gdArray.append(Variant(key))
                    }
                    self.config_updated.emit(gdArray)
                }
            }
        }
    }

    @Callable
    func stop_listening_for_updates() {
        configUpdateRegistration?.remove()
        configUpdateRegistration = nil
    }

    // MARK: - Helpers

    private func buildResult(status: Bool, error: String? = nil) -> GDictionary {
        var result = GDictionary()
        result[Variant("status")] = Variant(status)
        if let error { result[Variant("error")] = Variant(error) }
        return result
    }

    private func variantToNSObject(_ variant: Variant) -> NSObject {
        switch variant.gtype {
        case .bool:
            return NSNumber(value: Bool(variant) ?? false)
        case .int:
            return NSNumber(value: Int(variant) ?? 0)
        case .float:
            return NSNumber(value: Double(variant) ?? 0.0)
        case .string:
            return (String(variant) ?? "") as NSString
        default:
            return (String(variant) ?? "") as NSString
        }
    }
}
