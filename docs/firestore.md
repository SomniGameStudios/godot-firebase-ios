---
title: Cloud Firestore
nav_order: 3
layout: default
---

# Cloud Firestore

Cloud Firestore for iOS via the `FirebaseIOS.firestore` autoload.

## Signals

- `write_task_completed(status: bool, doc_id: String, data: Dictionary)`
  Emitted after `add_document()` or `set_document()` completes.

- `get_task_completed(status: bool, doc_id: String, data: Dictionary)`
  Emitted after `get_document()` completes, or once per document from `get_documents_in_collection()`.

- `update_task_completed(status: bool, doc_id: String)`
  Emitted after `update_document()` completes.

- `delete_task_completed(status: bool, doc_id: String)`
  Emitted after `delete_document()` completes.

- `document_changed(status: bool, doc_id: String, data: Dictionary)`
  Emitted when a listened document changes in real time.

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

## Example Usage

```gdscript
func _ready() -> void:
    FirebaseIOS.firestore.write_task_completed.connect(_on_write)
    FirebaseIOS.firestore.get_task_completed.connect(_on_get)

func _on_write(status: bool, doc_id: String, data: Dictionary) -> void:
    if status:
        print("Document written: ", doc_id)
        # Now read it back
        FirebaseIOS.firestore.get_document("users", doc_id)

func _on_get(status: bool, doc_id: String, data: Dictionary) -> void:
    if status:
        print("Document data: ", data)

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

- Queries with filters (where, order by, limit) are not yet supported. Use `get_documents_in_collection()` and filter in GDScript.
- Sub-collection operations are not directly supported. Use full document paths with `listen_to_document()`.
