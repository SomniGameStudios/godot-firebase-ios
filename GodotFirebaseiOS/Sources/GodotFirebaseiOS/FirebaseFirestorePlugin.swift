@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseFirestore

@Godot
class FirebaseFirestorePlugin: RefCounted, @unchecked Sendable {
    // Signals — match GodotFirebaseAndroid Firestore API
    @Signal("status", "doc_id", "data") var write_task_completed: SignalWithArguments<Bool, String, GDictionary>
    @Signal("status", "doc_id", "data") var get_task_completed: SignalWithArguments<Bool, String, GDictionary>
    @Signal("status", "doc_id") var update_task_completed: SignalWithArguments<Bool, String>
    @Signal("status", "doc_id") var delete_task_completed: SignalWithArguments<Bool, String>
    @Signal("status", "doc_id", "data") var document_changed: SignalWithArguments<Bool, String, GDictionary>

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
            Task { @MainActor in self.write_task_completed.emit(false, "", GDictionary()) }
            return
        }
        let swiftData = gdDictToSwift(data)
        var ref: DocumentReference?
        ref = db.collection(collection).addDocument(data: swiftData) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.write_task_completed.emit(false, "", GDictionary())
                    return
                }
                let docID = ref?.documentID ?? ""
                self.write_task_completed.emit(true, docID, data)
            }
        }
    }

    // MARK: - Set Document (explicit ID, with optional merge)

    @Callable
    func set_document(collection: String, documentId: String, data: GDictionary, merge: Bool) {
        guard let db else {
            Task { @MainActor in self.write_task_completed.emit(false, documentId, GDictionary()) }
            return
        }
        let swiftData = gdDictToSwift(data)
        db.collection(collection).document(documentId).setData(swiftData, merge: merge) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.write_task_completed.emit(false, documentId, GDictionary())
                    return
                }
                self.write_task_completed.emit(true, documentId, data)
            }
        }
    }

    // MARK: - Get Document

    @Callable
    func get_document(collection: String, documentId: String) {
        guard let db else {
            Task { @MainActor in self.get_task_completed.emit(false, documentId, GDictionary()) }
            return
        }
        db.collection(collection).document(documentId).getDocument { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.get_task_completed.emit(false, documentId, GDictionary())
                    return
                }
                let data = self.snapshotToGDDict(snapshot)
                self.get_task_completed.emit(true, documentId, data)
            }
        }
    }

    // MARK: - Get All Documents in Collection

    @Callable
    func get_documents_in_collection(collection: String) {
        guard let db else {
            Task { @MainActor in self.get_task_completed.emit(false, "", GDictionary()) }
            return
        }
        db.collection(collection).getDocuments { [weak self] querySnapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.get_task_completed.emit(false, "", GDictionary())
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    self.get_task_completed.emit(true, "", GDictionary())
                    return
                }
                for doc in documents {
                    let data = self.docDataToGDDict(doc.data())
                    self.get_task_completed.emit(true, doc.documentID, data)
                }
            }
        }
    }

    // MARK: - Update Document

    @Callable
    func update_document(collection: String, documentId: String, data: GDictionary) {
        guard let db else {
            Task { @MainActor in self.update_task_completed.emit(false, documentId) }
            return
        }
        let swiftData = gdDictToSwift(data)
        db.collection(collection).document(documentId).updateData(swiftData) { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.update_task_completed.emit(false, documentId)
                    return
                }
                self.update_task_completed.emit(true, documentId)
            }
        }
    }

    // MARK: - Delete Document

    @Callable
    func delete_document(collection: String, documentId: String) {
        guard let db else {
            Task { @MainActor in self.delete_task_completed.emit(false, documentId) }
            return
        }
        db.collection(collection).document(documentId).delete { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.delete_task_completed.emit(false, documentId)
                    return
                }
                self.delete_task_completed.emit(true, documentId)
            }
        }
    }

    // MARK: - Real-time Listeners

    @Callable
    func listen_to_document(documentPath: String) {
        guard let db else {
            Task { @MainActor in self.document_changed.emit(false, documentPath, GDictionary()) }
            return
        }
        if listeners[documentPath] != nil { return }
        let registration = db.document(documentPath).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.document_changed.emit(false, documentPath, GDictionary())
                    return
                }
                let data = self.snapshotToGDDict(snapshot)
                let docID = snapshot?.documentID ?? documentPath
                self.document_changed.emit(true, docID, data)
            }
        }
        listeners[documentPath] = registration
    }

    @Callable
    func stop_listening_to_document(documentPath: String) {
        listeners[documentPath]?.remove()
        listeners.removeValue(forKey: documentPath)
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
