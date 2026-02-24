extends Node

signal write_task_completed(status: bool, doc_id: String, data: Dictionary)
signal get_task_completed(status: bool, doc_id: String, data: Dictionary)
signal update_task_completed(status: bool, doc_id: String)
signal delete_task_completed(status: bool, doc_id: String)
signal document_changed(status: bool, doc_id: String, data: Dictionary)

var _plugin: Object

func _connect_signals():
	if not _plugin:
		return
	_plugin.connect("write_task_completed", write_task_completed.emit)
	_plugin.connect("get_task_completed", get_task_completed.emit)
	_plugin.connect("update_task_completed", update_task_completed.emit)
	_plugin.connect("delete_task_completed", delete_task_completed.emit)
	_plugin.connect("document_changed", document_changed.emit)

func initialize() -> void:
	if _plugin:
		_plugin.initialize()

func use_emulator(host: String, port: int) -> void:
	if _plugin:
		_plugin.use_emulator(host, port)

func add_document(collection: String, data: Dictionary) -> void:
	if _plugin:
		_plugin.add_document(collection, data)

func set_document(collection: String, document_id: String, data: Dictionary, merge: bool = false) -> void:
	if _plugin:
		_plugin.set_document(collection, document_id, data, merge)

func get_document(collection: String, document_id: String) -> void:
	if _plugin:
		_plugin.get_document(collection, document_id)

func get_documents_in_collection(collection: String) -> void:
	if _plugin:
		_plugin.get_documents_in_collection(collection)

func update_document(collection: String, document_id: String, data: Dictionary) -> void:
	if _plugin:
		_plugin.update_document(collection, document_id, data)

func delete_document(collection: String, document_id: String) -> void:
	if _plugin:
		_plugin.delete_document(collection, document_id)

func listen_to_document(document_path: String) -> void:
	if _plugin:
		_plugin.listen_to_document(document_path)

func stop_listening_to_document(document_path: String) -> void:
	if _plugin:
		_plugin.stop_listening_to_document(document_path)
