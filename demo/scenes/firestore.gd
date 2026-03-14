extends Control

@onready var output: RichTextLabel = %OutputPanel
@onready var collection_input: LineEdit = %CollectionInput
@onready var doc_id_input: LineEdit = %DocIdInput

func _ready() -> void:
	FirebaseIOS.firestore.write_task_completed.connect(_on_write_completed)
	FirebaseIOS.firestore.get_task_completed.connect(_on_get_completed)
	FirebaseIOS.firestore.update_task_completed.connect(_on_update_completed)
	FirebaseIOS.firestore.delete_task_completed.connect(_on_delete_completed)
	FirebaseIOS.firestore.document_changed.connect(_on_document_changed)
	FirebaseIOS.firestore.query_task_completed.connect(_on_query_completed)
	FirebaseIOS.firestore.collection_changed.connect(_on_collection_changed)
	FirebaseIOS.firestore.batch_task_completed.connect(_on_batch_completed)
	FirebaseIOS.firestore.transaction_task_completed.connect(_on_transaction_completed)

	_log("platform", "iOS")

# --- Signal handlers ---

func _on_write_completed(result: Dictionary) -> void:
	_log("write", "status=%s docID=%s data=%s" % [result.get("status"), result.get("docID", ""), JSON.stringify(result.get("data", {}))])

func _on_get_completed(result: Dictionary) -> void:
	_log("get", "status=%s docID=%s data=%s" % [result.get("status"), result.get("docID", ""), JSON.stringify(result.get("data", {}))])

func _on_update_completed(result: Dictionary) -> void:
	_log("update", "status=%s docID=%s" % [result.get("status"), result.get("docID", "")])

func _on_delete_completed(result: Dictionary) -> void:
	_log("delete", "status=%s docID=%s" % [result.get("status"), result.get("docID", "")])

func _on_document_changed(document_path: String, data: Dictionary) -> void:
	_log("listener", "path=%s data=%s" % [document_path, JSON.stringify(data)])

func _on_query_completed(result: Dictionary) -> void:
	_log("query", "status=%s docs=%s" % [result.get("status"), JSON.stringify(result.get("documents", []))])

func _on_collection_changed(collection_path: String, documents: Array) -> void:
	_log("collection", "path=%s count=%d" % [collection_path, documents.size()])

func _on_batch_completed(result: Dictionary) -> void:
	_log("batch", "status=%s error=%s" % [result.get("status"), result.get("error", "")])

func _on_transaction_completed(result: Dictionary) -> void:
	_log("transaction", "status=%s docID=%s data=%s" % [result.get("status"), result.get("docID", ""), JSON.stringify(result.get("data", {}))])

# --- CRUD Actions ---

func _on_add_document_pressed() -> void:
	var collection = collection_input.text
	var data = {"name": "Test", "value": 42, "timestamp": Time.get_unix_time_from_system()}
	_log("action", "Adding document to '%s'..." % collection)
	FirebaseIOS.firestore.add_document(collection, data)

func _on_set_document_pressed() -> void:
	var collection = collection_input.text
	var doc_id = doc_id_input.text
	var data = {"name": "Test", "value": 42}
	_log("action", "Setting document '%s/%s'..." % [collection, doc_id])
	FirebaseIOS.firestore.set_document(collection, doc_id, data)

func _on_get_document_pressed() -> void:
	var collection = collection_input.text
	var doc_id = doc_id_input.text
	_log("action", "Getting document '%s/%s'..." % [collection, doc_id])
	FirebaseIOS.firestore.get_document(collection, doc_id)

func _on_get_collection_pressed() -> void:
	var collection = collection_input.text
	_log("action", "Getting all documents in '%s'..." % collection)
	FirebaseIOS.firestore.get_documents_in_collection(collection)

func _on_update_document_pressed() -> void:
	var collection = collection_input.text
	var doc_id = doc_id_input.text
	var data = {"value": 99}
	_log("action", "Updating document '%s/%s'..." % [collection, doc_id])
	FirebaseIOS.firestore.update_document(collection, doc_id, data)

func _on_delete_document_pressed() -> void:
	var collection = collection_input.text
	var doc_id = doc_id_input.text
	_log("action", "Deleting document '%s/%s'..." % [collection, doc_id])
	FirebaseIOS.firestore.delete_document(collection, doc_id)

# --- Query Actions ---

func _on_query_pressed() -> void:
	var collection = collection_input.text
	var filters = [{"field": "value", "op": ">", "value": 10}]
	_log("action", "Querying '%s' where value > 10..." % collection)
	FirebaseIOS.firestore.query_documents(collection, filters)

func _on_query_ordered_pressed() -> void:
	var collection = collection_input.text
	_log("action", "Querying '%s' ordered by value desc, limit 5..." % collection)
	FirebaseIOS.firestore.query_documents(collection, [], "value", true, 5)

# --- Listener Actions ---

func _on_listen_pressed() -> void:
	var path = "%s/%s" % [collection_input.text, doc_id_input.text]
	_log("action", "Listening to '%s'..." % path)
	FirebaseIOS.firestore.listen_to_document(path)

func _on_stop_listen_pressed() -> void:
	var path = "%s/%s" % [collection_input.text, doc_id_input.text]
	_log("action", "Stopped listening to '%s'" % path)
	FirebaseIOS.firestore.stop_listening_to_document(path)

func _on_listen_collection_pressed() -> void:
	var collection = collection_input.text
	_log("action", "Listening to collection '%s'..." % collection)
	FirebaseIOS.firestore.listen_to_collection(collection)

func _on_stop_listen_collection_pressed() -> void:
	var collection = collection_input.text
	_log("action", "Stopped listening to collection '%s'" % collection)
	FirebaseIOS.firestore.stop_listening_to_collection(collection)

# --- Batch & Transaction Actions ---

func _on_batch_write_pressed() -> void:
	var collection = collection_input.text
	_log("action", "Running batch write on '%s'..." % collection)
	var batch_id = FirebaseIOS.firestore.create_batch()
	FirebaseIOS.firestore.batch_set(batch_id, collection, "batch_doc_1", {"name": "Batch1", "value": 10})
	FirebaseIOS.firestore.batch_set(batch_id, collection, "batch_doc_2", {"name": "Batch2", "value": 20})
	FirebaseIOS.firestore.batch_set(batch_id, collection, "batch_doc_3", {"name": "Batch3", "value": 30})
	FirebaseIOS.firestore.commit_batch(batch_id)

func _on_transaction_pressed() -> void:
	var collection = collection_input.text
	var doc_id = doc_id_input.text
	_log("action", "Running transaction on '%s/%s'..." % [collection, doc_id])
	FirebaseIOS.firestore.run_transaction(collection, doc_id, {"value": 999})

# --- FieldValue Actions ---

func _on_server_timestamp_pressed() -> void:
	var collection = collection_input.text
	var doc_id = doc_id_input.text
	_log("action", "Setting server timestamp on '%s/%s'..." % [collection, doc_id])
	var ts = FirebaseIOS.firestore.server_timestamp()
	FirebaseIOS.firestore.update_document(collection, doc_id, {"updated_at": ts})

func _on_increment_pressed() -> void:
	var collection = collection_input.text
	var doc_id = doc_id_input.text
	_log("action", "Incrementing value by 5 on '%s/%s'..." % [collection, doc_id])
	var inc = FirebaseIOS.firestore.increment_by(5)
	FirebaseIOS.firestore.update_document(collection, doc_id, {"value": inc})

# --- Logging ---

func _log(context: String, message: String) -> void:
	var t = Time.get_time_string_from_system()
	output.text += "[%s] %s: %s\n" % [t, context, message]
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	output.scroll_to_line(output.get_line_count())

# --- Navigation ---

func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://main.tscn"))

func _on_clear_output_pressed() -> void:
	output.text = ""
