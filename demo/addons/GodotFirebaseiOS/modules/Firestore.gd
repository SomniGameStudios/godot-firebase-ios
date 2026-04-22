extends Node

signal write_task_completed(result: Dictionary)
signal get_task_completed(result: Dictionary)
signal update_task_completed(result: Dictionary)
signal delete_task_completed(result: Dictionary)
signal document_changed(document_path: String, data: Dictionary)
signal query_task_completed(result: Dictionary)
signal collection_changed(collection_path: String, documents: Array)
signal batch_task_completed(result: Dictionary)
signal transaction_task_completed(result: Dictionary)

var _plugin: Object

func _connect_signals():
	if not _plugin:
		return
	_plugin.connect("write_task_completed", write_task_completed.emit)
	_plugin.connect("get_task_completed", get_task_completed.emit)
	_plugin.connect("update_task_completed", update_task_completed.emit)
	_plugin.connect("delete_task_completed", delete_task_completed.emit)
	_plugin.connect("document_changed", document_changed.emit)
	_plugin.connect("query_task_completed", query_task_completed.emit)
	_plugin.connect("collection_changed", collection_changed.emit)
	_plugin.connect("batch_task_completed", batch_task_completed.emit)
	_plugin.connect("transaction_task_completed", transaction_task_completed.emit)

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

# Query Documents

func query_documents(collection: String, filters: Array = [], order_by: String = "", order_descending: bool = false, limit_count: int = 0) -> void:
	if _plugin:
		_plugin.query_documents(collection, JSON.stringify(filters), order_by, order_descending, limit_count)

# Collection Listeners

func listen_to_collection(collection: String) -> void:
	if _plugin:
		_plugin.listen_to_collection(collection)

func stop_listening_to_collection(collection: String) -> void:
	if _plugin:
		_plugin.stop_listening_to_collection(collection)

# WriteBatch

func create_batch() -> int:
	if _plugin:
		return _plugin.create_batch()
	return -1

func batch_set(batch_id: int, collection: String, document_id: String, data: Dictionary, merge: bool = false) -> void:
	if _plugin:
		_plugin.batch_set(batch_id, collection, document_id, data, merge)

func batch_update(batch_id: int, collection: String, document_id: String, data: Dictionary) -> void:
	if _plugin:
		_plugin.batch_update(batch_id, collection, document_id, data)

func batch_delete(batch_id: int, collection: String, document_id: String) -> void:
	if _plugin:
		_plugin.batch_delete(batch_id, collection, document_id)

func commit_batch(batch_id: int) -> void:
	if _plugin:
		_plugin.commit_batch(batch_id)

# Transactions

func run_transaction(collection: String, document_id: String, update_data: Dictionary) -> void:
	if _plugin:
		_plugin.run_transaction(collection, document_id, update_data)

# FieldValue Helpers

func server_timestamp() -> Dictionary:
	if _plugin:
		return _plugin.server_timestamp()
	return {}

func array_union(elements: Array) -> Dictionary:
	if _plugin:
		return _plugin.array_union(JSON.stringify(elements))
	return {}

func array_remove(elements: Array) -> Dictionary:
	if _plugin:
		return _plugin.array_remove(JSON.stringify(elements))
	return {}

func increment_by(value: int) -> Dictionary:
	if _plugin:
		return _plugin.increment_by(value)
	return {}

func delete_field() -> Dictionary:
	if _plugin:
		return _plugin.delete_field()
	return {}
