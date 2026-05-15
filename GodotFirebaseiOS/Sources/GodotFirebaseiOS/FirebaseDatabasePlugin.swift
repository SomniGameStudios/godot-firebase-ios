@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseDatabase

@Godot
class FirebaseDatabasePlugin: RefCounted, @unchecked Sendable {
    // Signals — match GodotFirebaseAndroid RealtimeDatabase API
    @Signal("result") var realtime_write_task_completed: SignalWithArguments<GDictionary>
    @Signal("result") var realtime_get_task_completed: SignalWithArguments<GDictionary>
    @Signal("result") var realtime_update_task_completed: SignalWithArguments<GDictionary>
    @Signal("result") var realtime_delete_task_completed: SignalWithArguments<GDictionary>
    @Signal("path", "data") var realtime_db_value_changed: SignalWithArguments<String, GDictionary>

    private var ref: DatabaseReference?
    private var listeners: [String: DatabaseHandle] = [:]

    // MARK: - Setup

    @Callable
    func initialize() {
        guard FirebaseApp.app() != nil else { return }
        ref = Database.database().reference()
    }

    // MARK: - Core Methods

    @Callable
    func set_value(path: String, data: GDictionary) {
        guard let ref = ref else {
            Task { @MainActor in self.realtime_write_task_completed.emit(self.buildResult(status: false, path: path, error: "Database not initialized")) }
            return
        }
        let swiftData = variantToSwift(Variant(data))
        ref.child(path).setValue(swiftData) { [weak self] error, _ in
            guard let self else { return }
            Task { @MainActor in
                if let error = error {
                    self.realtime_write_task_completed.emit(self.buildResult(status: false, path: path, error: error.localizedDescription))
                } else {
                    self.realtime_write_task_completed.emit(self.buildResult(status: true, path: path))
                }
            }
        }
    }

    @Callable
    func get_value(path: String) {
        guard let ref = ref else {
            Task { @MainActor in self.realtime_get_task_completed.emit(self.buildResult(status: false, path: path, error: "Database not initialized")) }
            return
        }
        ref.child(path).getData { [weak self] error, snapshot in
            guard let self else { return }
            Task { @MainActor in
                if let error = error {
                    self.realtime_get_task_completed.emit(self.buildResult(status: false, path: path, error: error.localizedDescription))
                } else {
                    let data = self.snapshotToGDDict(snapshot)
                    self.realtime_get_task_completed.emit(self.buildResult(status: true, path: path, data: data))
                }
            }
        }
    }

    @Callable
    func update_value(path: String, data: GDictionary) {
        guard let ref = ref else {
            Task { @MainActor in self.realtime_update_task_completed.emit(self.buildResult(status: false, path: path, error: "Database not initialized")) }
            return
        }
        guard let swiftData = variantToSwift(Variant(data)) as? [String: Any] else {
            Task { @MainActor in self.realtime_update_task_completed.emit(self.buildResult(status: false, path: path, error: "Data must be a Dictionary for update")) }
            return
        }
        ref.child(path).updateChildValues(swiftData) { [weak self] error, _ in
            guard let self else { return }
            Task { @MainActor in
                if let error = error {
                    self.realtime_update_task_completed.emit(self.buildResult(status: false, path: path, error: error.localizedDescription))
                } else {
                    self.realtime_update_task_completed.emit(self.buildResult(status: true, path: path))
                }
            }
        }
    }

    @Callable
    func delete_value(path: String) {
        guard let ref = ref else {
            Task { @MainActor in self.realtime_delete_task_completed.emit(self.buildResult(status: false, path: path, error: "Database not initialized")) }
            return
        }
        ref.child(path).removeValue { [weak self] error, _ in
            guard let self else { return }
            Task { @MainActor in
                if let error = error {
                    self.realtime_delete_task_completed.emit(self.buildResult(status: false, path: path, error: error.localizedDescription))
                } else {
                    self.realtime_delete_task_completed.emit(self.buildResult(status: true, path: path))
                }
            }
        }
    }

    @Callable
    func listen_to_path(path: String) {
        guard let ref = ref else { return }
        stop_listening(path: path)
        
        let handle = ref.child(path).observe(.value) { [weak self] snapshot in
            guard let self else { return }
            Task { @MainActor in
                let data = self.snapshotToGDDict(snapshot)
                self.realtime_db_value_changed.emit(path, data)
            }
        }
        listeners[path] = handle
    }

    @Callable
    func stop_listening(path: String) {
        guard let ref = ref, let handle = listeners[path] else { return }
        ref.child(path).removeObserver(withHandle: handle)
        listeners.removeValue(forKey: path)
    }

    deinit {
        if let ref = ref {
            for (path, handle) in listeners {
                ref.child(path).removeObserver(withHandle: handle)
            }
        }
    }

    // MARK: - Increment Helper (Parity with Firestore increment)

    @Callable
    func increment(value: Int) -> GDictionary {
        var dict = GDictionary()
        dict[Variant("__type")] = Variant("increment")
        dict[Variant("value")] = Variant(value)
        return dict
    }

    // MARK: - Result Dictionary Builder

    private func buildResult(status: Bool, path: String, data: GDictionary? = nil, error: String? = nil) -> GDictionary {
        var result = GDictionary()
        result[Variant("status")] = Variant(status)
        result[Variant("path")] = Variant(path)
        if let data { result[Variant("data")] = Variant(data) }
        if let error { result[Variant("error")] = Variant(error) }
        return result
    }

    // MARK: - Data Conversion: Swift ← Godot

    private func variantToSwift(_ variant: Variant) -> Any? {
        switch variant.gtype {
        case .bool:
            return Bool(variant) ?? false
        case .int:
            return Int(variant) ?? 0
        case .float:
            return Double(variant) ?? 0.0
        case .string:
            return String(variant) ?? ""
        case .dictionary:
            guard let gdDict = GDictionary(variant) else { return [String: Any]() }
            
            // Check for RTDB increment sentinel
            if let typeVariant = gdDict[Variant("__type")], 
               let typeStr = String(typeVariant), 
               typeStr == "increment",
               let valVariant = gdDict[Variant("value")],
               let intVal = Int(valVariant) {
                return ServerValue.increment(NSNumber(value: intVal))
            }
            
            var result: [String: Any] = [:]
            let keys = gdDict.keys()
            for i in 0..<keys.size() {
                let key = keys[Int(i)]
                if let keyStr = String(key), let value = gdDict[key] {
                    result[keyStr] = variantToSwift(value)
                }
            }
            return result
        case .array:
            guard let gdArray = GArray(variant) else { return [Any]() }
            var result: [Any] = []
            for i in 0..<gdArray.size() {
                if let item = gdArray[Int(i)] {
                    result.append(variantToSwift(item) ?? NSNull())
                }
            }
            return result
        default:
            return String(variant) ?? ""
        }
    }

    // MARK: - Data Conversion: Swift → Godot

    private func snapshotToGDDict(_ snapshot: DataSnapshot?) -> GDictionary {
        var dict = GDictionary()
        guard let snapshot = snapshot, snapshot.exists() else { return dict }

        if snapshot.hasChildren() {
            if let children = snapshot.children.allObjects as? [DataSnapshot] {
                for child in children {
                    dict[Variant(child.key)] = swiftToVariant(child.value)
                }
            }
        } else {
            dict[Variant("value")] = swiftToVariant(snapshot.value)
        }
        return dict
    }

    private func swiftToVariant(_ value: Any?) -> Variant {
        guard let value = value, !(value is NSNull) else { return Variant(GDictionary()) }

        if let b = value as? Bool {
            return Variant(b)
        } else if let i = value as? Int {
            return Variant(i)
        } else if let i64 = value as? Int64 {
            return Variant(Int(i64))
        } else if let d = value as? Double {
            return Variant(d)
        } else if let f = value as? Float {
            return Variant(Double(f))
        } else if let s = value as? String {
            return Variant(s)
        } else if let dict = value as? [String: Any] {
            var gdDict = GDictionary()
            for (k, v) in dict {
                gdDict[Variant(k)] = swiftToVariant(v)
            }
            return Variant(gdDict)
        } else if let arr = value as? [Any] {
            var gdArray = GArray()
            for item in arr {
                gdArray.append(swiftToVariant(item))
            }
            return Variant(gdArray)
        }
        return Variant(String(describing: value))
    }
}
