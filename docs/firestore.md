---
title: Cloud Firestore
nav_order: 3
layout: default
---

# Cloud Firestore

Cloud Firestore for iOS via the `FirebaseIOS.firestore` autoload.

> **Official Firebase docs:** [Cloud Firestore](https://firebase.google.com/docs/firestore) · [Get started (iOS)](https://firebase.google.com/docs/firestore/ios/get-started)

## Signals

All task signals emit a single `result: Dictionary` with the following keys:
- `status` (bool) — `true` on success, `false` on failure
- `docID` (String) — the document ID
- `data` (Dictionary) — document data (when applicable)
- `error` (String) — error message (only on failure)

- `write_task_completed(result: Dictionary)`
  Emitted after `add_document()` or `set_document()` completes.

- `get_task_completed(result: Dictionary)`
  Emitted after `get_document()` completes, or once per document from `get_documents_in_collection()`.

- `update_task_completed(result: Dictionary)`
  Emitted after `update_document()` completes.

- `delete_task_completed(result: Dictionary)`
  Emitted after `delete_document()` completes.

- `document_changed(document_path: String, data: Dictionary)`
  Emitted when a listened document changes in real time.

- `query_task_completed(result: Dictionary)`
  Emitted after `query_documents()`. Result contains `{status: bool, collection: String, documents_json?: String, error?: String}`. On success, `documents_json` is a JSON array of flat documents shaped like `{"_docID": "...", ...fields}`.

- `collection_changed(collection_path: String, documents: Array)`
  Emitted when a listened collection changes. Each document in the array is `{docID: String, data: Dictionary}`.

- `batch_task_completed(result: Dictionary)`
  Emitted after `commit_batch()`. Result: `{status: bool, error?: String}`.

- `transaction_task_completed(result: Dictionary)`
  Emitted after `run_transaction()`. Result: `{status: bool, docID: String, data?: Dictionary, error?: String}`.

## Methods

{: .text-green-100 }
### add_document(collection: String, data: Dictionary)

Adds a new document with an auto-generated ID to the specified collection.

**Emits:** `write_task_completed` with the generated `doc_id`.

```gdscript
FirebaseIOS.firestore.add_document("users", {"name": "Alice", "score": 100})
```

---

{: .text-green-100 }
### set_document(collection: String, document_id: String, data: Dictionary, merge: bool = false)

Writes data to a document with an explicit ID. If `merge` is `true`, only the provided fields are updated; otherwise the entire document is overwritten.

**Emits:** `write_task_completed`.

```gdscript
FirebaseIOS.firestore.set_document("users", "alice123", {"name": "Alice", "score": 100})
# With merge:
FirebaseIOS.firestore.set_document("users", "alice123", {"score": 200}, true)
```

---

{: .text-green-100 }
### get_document(collection: String, document_id: String)

Retrieves a single document.

**Emits:** `get_task_completed`.

```gdscript
FirebaseIOS.firestore.get_document("users", "alice123")
```

---

{: .text-green-100 }
### get_documents_in_collection(collection: String)

Retrieves all documents in a collection. Emits one `get_task_completed` signal per document.

**Emits:** `get_task_completed` (once per document).

```gdscript
FirebaseIOS.firestore.get_documents_in_collection("users")
```

---

{: .text-green-100 }
### update_document(collection: String, document_id: String, data: Dictionary)

Updates specific fields on an existing document without overwriting the entire document.

**Emits:** `update_task_completed`.

```gdscript
FirebaseIOS.firestore.update_document("users", "alice123", {"score": 200})
```

---

{: .text-green-100 }
### delete_document(collection: String, document_id: String)

Deletes a document.

**Emits:** `delete_task_completed`.

```gdscript
FirebaseIOS.firestore.delete_document("users", "alice123")
```

---

{: .text-green-100 }
### listen_to_document(document_path: String)

Starts a real-time listener on a document. The `document_path` should be the full path (e.g., `"users/alice123"`).

**Emits:** `document_changed` whenever the document is created, modified, or deleted.

```gdscript
FirebaseIOS.firestore.listen_to_document("users/alice123")
```

---

{: .text-green-100 }
### stop_listening_to_document(document_path: String)

Stops a previously started real-time listener.

```gdscript
FirebaseIOS.firestore.stop_listening_to_document("users/alice123")
```

---

{: .text-green-100 }
### use_emulator(host: String, port: int)

Connects to the Firebase Firestore Emulator. Call this before any Firestore operations.

```gdscript
FirebaseIOS.firestore.use_emulator("localhost", 8080)
```

---

{: .text-green-100 }
### query_documents(collection: String, filters: Array, order_by: String, order_descending: bool, limit_count: int)

Queries documents with filters, ordering, and limits. Filters is an Array of Dictionaries: `[{"field": "score", "op": ">", "value": 100}]`. Supported operators: `==`, `!=`, `<`, `<=`, `>`, `>=`, `array_contains`, `in`, `not_in`, `array_contains_any`.

**Emits:** `query_task_completed` with `collection` echoed back and `documents_json` on success.

```gdscript
FirebaseIOS.firestore.query_documents("users", [{"field": "score", "op": ">", "value": 100}], "score", true, 10)
```

---

{: .text-green-100 }
### listen_to_collection(collection: String)

Starts a real-time listener on a collection.

**Emits:** `collection_changed`.

```gdscript
FirebaseIOS.firestore.listen_to_collection("users")
```

---

{: .text-green-100 }
### stop_listening_to_collection(collection: String)

Stops a previously started collection listener.

```gdscript
FirebaseIOS.firestore.stop_listening_to_collection("users")
```

---

{: .text-green-100 }
### create_batch() -> int

Creates a new write batch and returns the batch ID.

```gdscript
var batch_id = FirebaseIOS.firestore.create_batch()
```

---

{: .text-green-100 }
### batch_set(batch_id: int, collection: String, document_id: String, data: Dictionary, merge: bool)

Adds a set operation to the specified batch.

```gdscript
FirebaseIOS.firestore.batch_set(batch_id, "users", "alice123", {"name": "Alice", "score": 100}, false)
```

---

{: .text-green-100 }
### batch_update(batch_id: int, collection: String, document_id: String, data: Dictionary)

Adds an update operation to the specified batch.

```gdscript
FirebaseIOS.firestore.batch_update(batch_id, "users", "alice123", {"score": 200})
```

---

{: .text-green-100 }
### batch_delete(batch_id: int, collection: String, document_id: String)

Adds a delete operation to the specified batch.

```gdscript
FirebaseIOS.firestore.batch_delete(batch_id, "users", "alice123")
```

---

{: .text-green-100 }
### commit_batch(batch_id: int)

Commits all operations in the batch atomically.

**Emits:** `batch_task_completed`.

```gdscript
FirebaseIOS.firestore.commit_batch(batch_id)
```

---

{: .text-green-100 }
### run_transaction(collection: String, document_id: String, update_data: Dictionary)

Runs a read-then-update transaction on a document.

**Emits:** `transaction_task_completed`.

```gdscript
FirebaseIOS.firestore.run_transaction("users", "alice123", {"score": 200})
```

---

{: .text-green-100 }
### server_timestamp() -> Dictionary

Returns a sentinel value for a server-generated timestamp.

```gdscript
var timestamp = FirebaseIOS.firestore.server_timestamp()
```

---

{: .text-green-100 }
### array_union(elements: Array) -> Dictionary

Returns a sentinel value for an array union operation.

```gdscript
var union = FirebaseIOS.firestore.array_union(["tag1", "tag2"])
```

---

{: .text-green-100 }
### array_remove(elements: Array) -> Dictionary

Returns a sentinel value for an array remove operation.

```gdscript
var remove = FirebaseIOS.firestore.array_remove(["tag1"])
```

---

{: .text-green-100 }
### increment_by(value: int) -> Dictionary

Returns a sentinel value for an atomic increment operation.

```gdscript
var inc = FirebaseIOS.firestore.increment_by(1)
```

---

{: .text-green-100 }
### delete_field() -> Dictionary

Returns a sentinel value to delete a field from a document.

```gdscript
var del = FirebaseIOS.firestore.delete_field()
```

---

## Example Usage

```gdscript
func _ready() -> void:
    FirebaseIOS.firestore.write_task_completed.connect(_on_write)
    FirebaseIOS.firestore.get_task_completed.connect(_on_get)

func _on_write(result: Dictionary) -> void:
    if result.get("status"):
        print("Document written: ", result.get("docID"))
        # Now read it back
        FirebaseIOS.firestore.get_document("users", result.get("docID"))
    else:
        print("Write failed: ", result.get("error"))

func _on_get(result: Dictionary) -> void:
    if result.get("status"):
        print("Document data: ", result.get("data"))

func create_user() -> void:
    FirebaseIOS.firestore.add_document("users", {
        "name": "Alice",
        "score": 100,
        "active": true
    })
```

## Data Type Mapping

| GDScript Type | Firestore Type |
|---------------|---------------|
| `bool` | Boolean |
| `int` | Integer |
| `float` | Double |
| `String` | String |
| `Dictionary` | Map |
| `Array` | Array |

Firestore `Timestamp` values are returned as ISO 8601 strings.

## Known Limitations

- Sub-collection operations are not directly supported. Use full document paths with `listen_to_document()`.
