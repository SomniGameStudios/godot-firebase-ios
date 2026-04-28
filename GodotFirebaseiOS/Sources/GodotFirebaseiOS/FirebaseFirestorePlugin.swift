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

    // New signals for queries, collection listeners, batches, transactions
    @Signal("result") var query_task_completed: SignalWithArguments<GDictionary>
    @Signal("collection_path", "documents") var collection_changed: SignalWithArguments<String, GArray>
    @Signal("result") var batch_task_completed: SignalWithArguments<GDictionary>
    @Signal("result") var transaction_task_completed: SignalWithArguments<GDictionary>

    private var db: Firestore?
    private var listeners: [String: ListenerRegistration] = [:]
    private var collectionListeners: [String: ListenerRegistration] = [:]
    private var batches: [Int: WriteBatch] = [:]
    private var nextBatchId: Int = 0

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

    // MARK: - Real-time Document Listeners

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

    // MARK: - Query Documents

    @Callable
    func query_documents(collection: String, filtersJson: String, orderBy: String, orderDescending: Bool, limitCount: Int) {
        guard let db else {
            Task { @MainActor in self.query_task_completed.emit(self.buildQueryResult(status: false, collection: collection, error: "Firestore not initialized")) }
            return
        }
        var query: Query = db.collection(collection)

        // Parse filters from JSON
        guard let data = filtersJson.data(using: .utf8) else {
            let result = buildQueryResult(status: false, collection: collection, error: "Invalid filters JSON: not UTF-8")
            Task { @MainActor in self.query_task_completed.emit(result) }
            return
        }

        let parsed: [[String: Any]]
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            guard let arr = obj as? [[String: Any]] else {
                let result = buildQueryResult(status: false, collection: collection, error: "Filters JSON must be an array of objects")
                Task { @MainActor in self.query_task_completed.emit(result) }
                return
            }
            parsed = arr
        } catch {
            let result = buildQueryResult(status: false, collection: collection, error: "Invalid filters JSON: \(error.localizedDescription)")
            Task { @MainActor in self.query_task_completed.emit(result) }
            return
        }

        // Apply filters
        for item in parsed {
            guard let field = item["field"] as? String,
                  let op = item["op"] as? String,
                  let value = item["value"] else { continue }

            switch op {
            case "==":
                query = query.whereField(field, isEqualTo: value)
            case "!=":
                query = query.whereField(field, isNotEqualTo: value)
            case "<":
                query = query.whereField(field, isLessThan: value)
            case "<=":
                query = query.whereField(field, isLessThanOrEqualTo: value)
            case ">":
                query = query.whereField(field, isGreaterThan: value)
            case ">=":
                query = query.whereField(field, isGreaterThanOrEqualTo: value)
            case "array_contains":
                query = query.whereField(field, arrayContains: value)
            case "in":
                let list = (value as? [Any]) ?? [value]
                query = query.whereField(field, in: list)
            case "not_in":
                let list = (value as? [Any]) ?? [value]
                query = query.whereField(field, notIn: list)
            case "array_contains_any":
                let list = (value as? [Any]) ?? [value]
                query = query.whereField(field, arrayContainsAny: list)
            default:
                break
            }
        }

        // Apply ordering
        if !orderBy.isEmpty {
            query = query.order(by: orderBy, descending: orderDescending)
        }

        // Apply limit
        if limitCount > 0 {
            query = query.limit(to: limitCount)
        }

        query.getDocuments { [weak self] querySnapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.query_task_completed.emit(self.buildQueryResult(status: false, collection: collection, error: error.localizedDescription))
                    return
                }
                let documents = querySnapshot?.documents ?? []
                var serializedDocs: [[String: Any]] = []
                serializedDocs.reserveCapacity(documents.count)
                for doc in documents {
                    var flatDoc = self.docDataToSwiftDictionary(doc.data())
                    flatDoc["_docID"] = doc.documentID
                    serializedDocs.append(flatDoc)
                }
                let result = self.buildQueryResult(
                    status: true,
                    collection: collection,
                    documentsJson: self.encodeDocumentsJson(serializedDocs)
                )
                self.query_task_completed.emit(result)
            }
        }
    }

    // MARK: - Real-time Collection Listeners

    @Callable
    func listen_to_collection(collection: String) {
        guard let db else {
            Task { @MainActor in self.collection_changed.emit(collection, GArray()) }
            return
        }
        if collectionListeners[collection] != nil { return }
        let registration = db.collection(collection).addSnapshotListener { [weak self] querySnapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if error != nil {
                    self.collection_changed.emit(collection, GArray())
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    self.collection_changed.emit(collection, GArray())
                    return
                }
                var docsArray = GArray()
                for doc in documents {
                    var docDict = GDictionary()
                    docDict[Variant("docID")] = Variant(doc.documentID)
                    docDict[Variant("data")] = Variant(self.docDataToGDDict(doc.data()))
                    docsArray.append(Variant(docDict))
                }
                self.collection_changed.emit(collection, docsArray)
            }
        }
        collectionListeners[collection] = registration
    }

    @Callable
    func stop_listening_to_collection(collection: String) {
        collectionListeners[collection]?.remove()
        collectionListeners.removeValue(forKey: collection)
    }

    // MARK: - WriteBatch

    @Callable
    func create_batch() -> Int {
        guard let db else { return -1 }
        let batchId = nextBatchId
        nextBatchId += 1
        batches[batchId] = db.batch()
        return batchId
    }

    @Callable
    func batch_set(batchId: Int, collection: String, documentId: String, data: GDictionary, merge: Bool) {
        guard let db, let batch = batches[batchId] else { return }
        let ref = db.collection(collection).document(documentId)
        let swiftData = gdDictToSwift(data)
        batch.setData(swiftData, forDocument: ref, merge: merge)
    }

    @Callable
    func batch_update(batchId: Int, collection: String, documentId: String, data: GDictionary) {
        guard let db, let batch = batches[batchId] else { return }
        let ref = db.collection(collection).document(documentId)
        let swiftData = gdDictToSwift(data)
        batch.updateData(swiftData, forDocument: ref)
    }

    @Callable
    func batch_delete(batchId: Int, collection: String, documentId: String) {
        guard let db, let batch = batches[batchId] else { return }
        let ref = db.collection(collection).document(documentId)
        batch.deleteDocument(ref)
    }

    @Callable
    func commit_batch(batchId: Int) {
        guard let batch = batches[batchId] else {
            Task { @MainActor in self.batch_task_completed.emit(self.buildResult(status: false, docID: "", error: "Invalid batch ID")) }
            return
        }
        batch.commit { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                self.batches.removeValue(forKey: batchId)
                if let error {
                    self.batch_task_completed.emit(self.buildResult(status: false, docID: "", error: error.localizedDescription))
                    return
                }
                self.batch_task_completed.emit(self.buildResult(status: true, docID: ""))
            }
        }
    }

    // MARK: - Transactions

    @Callable
    func run_transaction(collection: String, documentId: String, updateData: GDictionary) {
        guard let db else {
            Task { @MainActor in self.transaction_task_completed.emit(self.buildResult(status: false, docID: documentId, error: "Firestore not initialized")) }
            return
        }
        let ref = db.collection(collection).document(documentId)
        let swiftUpdateData = gdDictToSwift(updateData)

        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self else { return nil }
            let snapshot: DocumentSnapshot
            do {
                try snapshot = transaction.getDocument(ref)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            transaction.updateData(swiftUpdateData, forDocument: ref)
            return snapshot.data()
        }) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.transaction_task_completed.emit(self.buildResult(status: false, docID: documentId, error: error.localizedDescription))
                    return
                }
                if let data = result as? [String: Any] {
                    self.transaction_task_completed.emit(self.buildResult(status: true, docID: documentId, data: self.docDataToGDDict(data)))
                } else {
                    self.transaction_task_completed.emit(self.buildResult(status: true, docID: documentId))
                }
            }
        }
    }

    // MARK: - FieldValue Helpers

    @Callable
    func server_timestamp() -> GDictionary {
        var dict = GDictionary()
        dict[Variant("__type")] = Variant("serverTimestamp")
        return dict
    }

    @Callable
    func array_union(elementsJson: String) -> GDictionary {
        var dict = GDictionary()
        dict[Variant("__type")] = Variant("arrayUnion")
        dict[Variant("elementsJson")] = Variant(elementsJson)
        return dict
    }

    @Callable
    func array_remove(elementsJson: String) -> GDictionary {
        var dict = GDictionary()
        dict[Variant("__type")] = Variant("arrayRemove")
        dict[Variant("elementsJson")] = Variant(elementsJson)
        return dict
    }

    @Callable
    func increment_by(value: Int) -> GDictionary {
        var dict = GDictionary()
        dict[Variant("__type")] = Variant("increment")
        dict[Variant("value")] = Variant(value)
        return dict
    }

    @Callable
    func delete_field() -> GDictionary {
        var dict = GDictionary()
        dict[Variant("__type")] = Variant("deleteField")
        return dict
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

    private func buildQueryResult(status: Bool, collection: String, documentsJson: String? = nil, error: String? = nil) -> GDictionary {
        var result = GDictionary()
        result[Variant("status")] = Variant(status)
        result[Variant("collection")] = Variant(collection)
        if let documentsJson { result[Variant("documents_json")] = Variant(documentsJson) }
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

            // Check for FieldValue sentinels
            if value.gtype == .dictionary, let innerDict = GDictionary(value) {
                if let typeVariant = innerDict[Variant("__type")], let typeStr = String(typeVariant) {
                    switch typeStr {
                    case "serverTimestamp":
                        result[keyStr] = FieldValue.serverTimestamp()
                        continue
                    case "deleteField":
                        result[keyStr] = FieldValue.delete()
                        continue
                    case "increment":
                        if let valVariant = innerDict[Variant("value")], let intVal = Int(valVariant) {
                            result[keyStr] = FieldValue.increment(Int64(intVal))
                        }
                        continue
                    case "arrayUnion":
                        if let jsonVariant = innerDict[Variant("elementsJson")], let json = String(jsonVariant) {
                            result[keyStr] = FieldValue.arrayUnion(parseJsonElementsArray(json))
                        }
                        continue
                    case "arrayRemove":
                        if let jsonVariant = innerDict[Variant("elementsJson")], let json = String(jsonVariant) {
                            result[keyStr] = FieldValue.arrayRemove(parseJsonElementsArray(json))
                        }
                        continue
                    default:
                        break
                    }
                }
            }

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

    private func parseJsonElementsArray(_ json: String) -> [Any] {
        guard !json.isEmpty,
              let data = json.data(using: .utf8) else { return [] }
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            return (obj as? [Any]) ?? []
        } catch {
            return []
        }
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

    private func docDataToSwiftDictionary(_ data: [String: Any]) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict.reserveCapacity(data.count)
        for (key, value) in data {
            dict[key] = toJsonSafe(value)
        }
        return dict
    }

    private func encodeDocumentsJson(_ documents: [[String: Any]]) -> String {
        guard JSONSerialization.isValidJSONObject(documents),
              let data = try? JSONSerialization.data(withJSONObject: documents, options: []) else {
            return "[]"
        }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func toJsonSafe(_ value: Any) -> Any {
        switch value {
        case let b as Bool:
            return b
        case let i as Int:
            return i
        case let i as Int64:
            return Int(i)
        case let d as Double:
            return d
        case let f as Float:
            return Double(f)
        case let s as String:
            return s
        case let ts as Timestamp:
            return ts.seconds
        case let dict as [String: Any]:
            return docDataToSwiftDictionary(dict)
        case let arr as [Any]:
            return arr.map { toJsonSafe($0) }
        default:
            return String(describing: value)
        }
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
