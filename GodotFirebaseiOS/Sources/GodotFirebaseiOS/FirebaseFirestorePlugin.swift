@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseFirestore

@Godot
class FirebaseFirestorePlugin: RefCounted, @unchecked Sendable {
    // Signals — match GodotFirebaseAndroid Firestore API
    @Signal("result") var write_task_completed: SignalWithArguments<GDictionary>
    @Signal("result") var get_task_completed: SignalWithArguments<GDictionary>
    @Signal("result") var update_task_completed: SignalWithArguments<GDictionary>
    @Signal("result") var delete_task_completed: SignalWithArguments<GDictionary>
    @Signal("document_path", "data") var document_changed: SignalWithArguments<String, GDictionary>

    private var db: Firestore?
    private var listeners: [String: ListenerRegistration] = [:]

    // MARK: - Setup

    @Callable
    func initialize() {
        guard FirebaseApp.app() != nil else { return }
        db = Firestore.firestore()
    }

    @Callable
    func use_emulator(host: String, port: Int) {
        guard let db else { return }
        let settings = db.settings
        settings.host = "\(host):\(port)"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings
    }

    // MARK: - Add Document (auto-generated ID)

    @Callable
    func add_document(collection: String, data: GDictionary) {
        guard let db else {
            Task { @MainActor in self.write_task_completed.emit(self.buildResult(status: false, docID: "", error: "Firestore not initialized")) }
            return
        }
        let swiftData = gdDictToSwift(data)
        var ref: DocumentReference?
        ref = db.collection(collection).addDocument(data: swiftData) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.write_task_completed.emit(self.buildResult(status: false, docID: "", error: error.localizedDescription))
                    return
                }
                let docID = ref?.documentID ?? ""
                self.write_task_completed.emit(self.buildResult(status: true, docID: docID, data: data))
            }
        }
    }

    // MARK: - Set Document (explicit ID, with optional merge)

    @Callable
    func set_document(collection: String, documentId: String, data: GDictionary, merge: Bool) {
        guard let db else {
            Task { @MainActor in self.write_task_completed.emit(self.buildResult(status: false, docID: documentId, error: "Firestore not initialized")) }
            return
        }
        let swiftData = gdDictToSwift(data)
        db.collection(collection).document(documentId).setData(swiftData, merge: merge) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.write_task_completed.emit(self.buildResult(status: false, docID: documentId, error: error.localizedDescription))
                    return
                }
                self.write_task_completed.emit(self.buildResult(status: true, docID: documentId, data: data))
            }
        }
    }

    // MARK: - Get Document

    @Callable
    func get_document(collection: String, documentId: String) {
        guard let db else {
            Task { @MainActor in self.get_task_completed.emit(self.buildResult(status: false, docID: documentId, error: "Firestore not initialized")) }
            return
        }
        db.collection(collection).document(documentId).getDocument { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.get_task_completed.emit(self.buildResult(status: false, docID: documentId, error: error.localizedDescription))
                    return
                }
                let data = self.snapshotToGDDict(snapshot)
                self.get_task_completed.emit(self.buildResult(status: true, docID: documentId, data: data))
            }
        }
    }

    // MARK: - Get All Documents in Collection

    @Callable
    func get_documents_in_collection(collection: String) {
        guard let db else {
            Task { @MainActor in self.get_task_completed.emit(self.buildResult(status: false, docID: "", error: "Firestore not initialized")) }
            return
        }
        db.collection(collection).getDocuments { [weak self] querySnapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.get_task_completed.emit(self.buildResult(status: false, docID: "", error: error.localizedDescription))
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    self.get_task_completed.emit(self.buildResult(status: true, docID: ""))
                    return
                }
                for doc in documents {
                    let data = self.docDataToGDDict(doc.data())
                    self.get_task_completed.emit(self.buildResult(status: true, docID: doc.documentID, data: data))
                }
            }
        }
    }

    // MARK: - Update Document

    @Callable
    func update_document(collection: String, documentId: String, data: GDictionary) {
        guard let db else {
            Task { @MainActor in self.update_task_completed.emit(self.buildResult(status: false, docID: documentId, error: "Firestore not initialized")) }
            return
        }
        let swiftData = gdDictToSwift(data)
        db.collection(collection).document(documentId).updateData(swiftData) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.update_task_completed.emit(self.buildResult(status: false, docID: documentId, error: error.localizedDescription))
                    return
                }
                self.update_task_completed.emit(self.buildResult(status: true, docID: documentId))
            }
        }
    }

    // MARK: - Delete Document

    @Callable
    func delete_document(collection: String, documentId: String) {
        guard let db else {
            Task { @MainActor in self.delete_task_completed.emit(self.buildResult(status: false, docID: documentId, error: "Firestore not initialized")) }
            return
        }
        db.collection(collection).document(documentId).delete { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.delete_task_completed.emit(self.buildResult(status: false, docID: documentId, error: error.localizedDescription))
                    return
                }
                self.delete_task_completed.emit(self.buildResult(status: true, docID: documentId))
            }
        }
    }

    // MARK: - Real-time Listeners

    @Callable
    func listen_to_document(documentPath: String) {
        guard let db else {
            Task { @MainActor in self.document_changed.emit(documentPath, GDictionary()) }
            return
        }
        if listeners[documentPath] != nil { return }
        let registration = db.document(documentPath).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.document_changed.emit(documentPath, GDictionary())
                    return
                }
                let data = self.snapshotToGDDict(snapshot)
                self.document_changed.emit(documentPath, data)
            }
        }
        listeners[documentPath] = registration
    }

    @Callable
    func stop_listening_to_document(documentPath: String) {
        listeners[documentPath]?.remove()
        listeners.removeValue(forKey: documentPath)
    }

    // MARK: - Result Dictionary Builder

    private func buildResult(status: Bool, docID: String, data: GDictionary? = nil, error: String? = nil) -> GDictionary {
        var result = GDictionary()
        result[Variant("status")] = Variant(status)
        result[Variant("docID")] = Variant(docID)
        if let data { result[Variant("data")] = Variant(data) }
        if let error { result[Variant("error")] = Variant(error) }
        return result
    }

    // MARK: - Data Conversion: GDictionary → Swift

    private func gdDictToSwift(_ gdDict: GDictionary) -> [String: Any] {
        var result: [String: Any] = [:]
        let keys = gdDict.keys()
        for i in 0..<keys.size() {
            let keyVariant = keys[Int(i)]
            guard let keyStr = String(keyVariant) else { continue }
            guard let value = gdDict[keyVariant] else { continue }
            result[keyStr] = variantToSwift(value)
        }
        return result
    }

    private func variantToSwift(_ variant: Variant) -> Any {
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
            if let gd = GDictionary(variant) {
                return gdDictToSwift(gd)
            }
            return [String: Any]()
        case .array:
            if let ga = GArray(variant) {
                return gdArrayToSwift(ga)
            }
            return [Any]()
        default:
            return String(variant) ?? ""
        }
    }

    private func gdArrayToSwift(_ gdArray: GArray) -> [Any] {
        var result: [Any] = []
        for i in 0..<gdArray.size() {
            guard let variant = gdArray[Int(i)] else { continue }
            result.append(variantToSwift(variant))
        }
        return result
    }

    // MARK: - Data Conversion: Swift → GDictionary

    private func snapshotToGDDict(_ snapshot: DocumentSnapshot?) -> GDictionary {
        guard let data = snapshot?.data() else { return GDictionary() }
        return docDataToGDDict(data)
    }

    private func docDataToGDDict(_ data: [String: Any]) -> GDictionary {
        var dict = GDictionary()
        for (key, value) in data {
            dict[Variant(key)] = swiftToVariant(value)
        }
        return dict
    }

    private func swiftToVariant(_ value: Any) -> Variant {
        switch value {
        case let b as Bool:
            return Variant(b)
        case let i as Int:
            return Variant(i)
        case let i as Int64:
            return Variant(Int(i))
        case let d as Double:
            return Variant(d)
        case let s as String:
            return Variant(s)
        case let ts as Timestamp:
            let formatter = ISO8601DateFormatter()
            return Variant(formatter.string(from: ts.dateValue()))
        case let dict as [String: Any]:
            return Variant(docDataToGDDict(dict))
        case let arr as [Any]:
            var gdArray = GArray()
            for item in arr {
                gdArray.append(swiftToVariant(item))
            }
            return Variant(gdArray)
        default:
            return Variant(String(describing: value))
        }
    }
}
