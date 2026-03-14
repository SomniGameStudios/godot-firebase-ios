extends Node

signal fetch_completed(result: Dictionary)
signal activate_completed(result: Dictionary)
signal config_updated(updated_keys: Array)

var _plugin: Object

func _connect_signals():
	if not _plugin:
		return
	_plugin.connect("fetch_completed", fetch_completed.emit)
	_plugin.connect("activate_completed", activate_completed.emit)
	_plugin.connect("config_updated", config_updated.emit)

func initialize() -> void:
	if _plugin:
		_plugin.initialize()

func set_defaults(defaults: Dictionary) -> void:
	if _plugin:
		_plugin.set_defaults(defaults)

func set_minimum_fetch_interval(seconds: int) -> void:
	if _plugin:
		_plugin.set_minimum_fetch_interval(seconds)

func fetch() -> void:
	if _plugin:
		_plugin.fetch()

func activate() -> void:
	if _plugin:
		_plugin.activate()

func fetch_and_activate() -> void:
	if _plugin:
		_plugin.fetch_and_activate()

func get_string(key: String) -> String:
	if _plugin:
		return _plugin.get_string(key)
	return ""

func get_bool(key: String) -> bool:
	if _plugin:
		return _plugin.get_bool(key)
	return false

func get_int(key: String) -> int:
	if _plugin:
		return _plugin.get_int(key)
	return 0

func get_float(key: String) -> float:
	if _plugin:
		return _plugin.get_float(key)
	return 0.0

func get_all() -> Dictionary:
	if _plugin:
		return _plugin.get_all()
	return {}

func listen_for_updates() -> void:
	if _plugin:
		_plugin.listen_for_updates()

func stop_listening_for_updates() -> void:
	if _plugin:
		_plugin.stop_listening_for_updates()

# Additional getters

func get_json(key: String) -> String:
	if _plugin:
		return _plugin.get_json(key)
	return ""

func get_value_source(key: String) -> int:
	if _plugin:
		return _plugin.get_value_source(key)
	return 0

func get_last_fetch_status() -> int:
	if _plugin:
		return _plugin.get_last_fetch_status()
	return -1

func get_last_fetch_time() -> String:
	if _plugin:
		return _plugin.get_last_fetch_time()
	return ""

func set_fetch_timeout(seconds: int) -> void:
	if _plugin:
		_plugin.set_fetch_timeout(seconds)
