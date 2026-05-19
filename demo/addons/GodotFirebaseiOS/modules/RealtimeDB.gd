extends Node

signal write_task_completed(result: Dictionary)
signal get_task_completed(result: Dictionary)
signal update_task_completed(result: Dictionary)
signal delete_task_completed(result: Dictionary)
signal db_value_changed(path: String, data: Dictionary)

var _plugin: Object

func _connect_signals() -> void:
	if not _plugin:
		return
	_plugin.connect("realtime_write_task_completed", write_task_completed.emit)
	_plugin.connect("realtime_get_task_completed", get_task_completed.emit)
	_plugin.connect("realtime_update_task_completed", update_task_completed.emit)
	_plugin.connect("realtime_delete_task_completed", delete_task_completed.emit)
	_plugin.connect("realtime_db_value_changed", db_value_changed.emit)

func initialize() -> void:
	if _plugin:
		_plugin.initialize()

func set_value(path: String, data: Dictionary) -> void:
	if _plugin:
		_plugin.set_value(path, data)

func get_value(path: String) -> void:
	if _plugin:
		_plugin.get_value(path)

func update_value(path: String, data: Dictionary) -> void:
	if _plugin:
		_plugin.update_value(path, data)

func delete_value(path: String) -> void:
	if _plugin:
		_plugin.delete_value(path)

func listen_to_path(path: String) -> void:
	if _plugin:
		_plugin.listen_to_path(path)

func stop_listening(path: String) -> void:
	if _plugin:
		_plugin.stop_listening(path)

func increment(value: int) -> Dictionary:
	if _plugin:
		return _plugin.increment(value)
	return {}
