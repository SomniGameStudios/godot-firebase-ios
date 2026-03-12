extends Node

var _plugin: Object

func _connect_signals():
	pass

func log_event(event_name: String, parameters: Dictionary = {}) -> void:
	if _plugin:
		_plugin.log_event(event_name, parameters)

func set_user_property(value: String, name: String) -> void:
	if _plugin:
		_plugin.set_user_property(value, name)

func set_user_id(id: String) -> void:
	if _plugin:
		_plugin.set_user_id(id)

func set_analytics_collection_enabled(enabled: bool) -> void:
	if _plugin:
		_plugin.set_analytics_collection_enabled(enabled)

func set_default_event_parameters(parameters: Dictionary) -> void:
	if _plugin:
		_plugin.set_default_event_parameters(parameters)

func reset_analytics_data() -> void:
	if _plugin:
		_plugin.reset_analytics_data()

func get_app_instance_id() -> String:
	if _plugin:
		return _plugin.get_app_instance_id()
	return ""

func set_consent(ad_storage: bool, analytics_storage: bool) -> void:
	if _plugin:
		_plugin.set_consent(ad_storage, analytics_storage)

func set_session_timeout(seconds: int) -> void:
	if _plugin:
		_plugin.set_session_timeout(seconds)
