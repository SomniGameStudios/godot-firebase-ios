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

	_log("platform", "iOS")

# --- Signal handlers ---

func _on_write_completed(status: bool, doc_id: String, data: Dictionary) -> void:
	_log("write", "status=%s doc_id=%s data=%s" % [status, doc_id, JSON.stringify(data)])

func _on_get_completed(status: bool, doc_id: String, data: Dictionary) -> void:
	_log("get", "status=%s doc_id=%s data=%s" % [status, doc_id, JSON.stringify(data)])

func _on_update_completed(status: bool, doc_id: String) -> void:
	_log("update", "status=%s doc_id=%s" % [status, doc_id])

func _on_delete_completed(status: bool, doc_id: String) -> void:
	_log("delete", "status=%s doc_id=%s" % [status, doc_id])

func _on_document_changed(status: bool, doc_id: String, data: Dictionary) -> void:
	_log("listener", "status=%s doc_id=%s data=%s" % [status, doc_id, JSON.stringify(data)])

# --- Actions ---

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

func _on_listen_pressed() -> void:
	var path = "%s/%s" % [collection_input.text, doc_id_input.text]
	_log("action", "Listening to '%s'..." % path)
	FirebaseIOS.firestore.listen_to_document(path)

func _on_stop_listen_pressed() -> void:
	var path = "%s/%s" % [collection_input.text, doc_id_input.text]
	_log("action", "Stopped listening to '%s'" % path)
	FirebaseIOS.firestore.stop_listening_to_document(path)

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
