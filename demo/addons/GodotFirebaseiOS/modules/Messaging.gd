extends Node

signal token_received(token: String)
signal token_error(message: String)
signal notification_received(data: Dictionary)
signal notification_opened(data: Dictionary)
signal permission_result(granted: bool)
signal topic_subscribe_success(topic: String)
signal topic_subscribe_failure(message: String)
signal topic_unsubscribe_success(topic: String)
signal topic_unsubscribe_failure(message: String)
signal token_delete_success()
signal token_delete_failure(message: String)

var _plugin: Object

func _connect_signals():
	if not _plugin:
		return
	_plugin.connect("token_received", token_received.emit)
	_plugin.connect("token_error", token_error.emit)
	_plugin.connect("notification_received", notification_received.emit)
	_plugin.connect("notification_opened", notification_opened.emit)
	_plugin.connect("permission_result", permission_result.emit)
	_plugin.connect("topic_subscribe_success", topic_subscribe_success.emit)
	_plugin.connect("topic_subscribe_failure", topic_subscribe_failure.emit)
	_plugin.connect("topic_unsubscribe_success", topic_unsubscribe_success.emit)
	_plugin.connect("topic_unsubscribe_failure", topic_unsubscribe_failure.emit)
	_plugin.connect("token_delete_success", token_delete_success.emit)
	_plugin.connect("token_delete_failure", token_delete_failure.emit)

func configure() -> void:
	if _plugin:
		_plugin.configure()

func request_permission(provisional: bool = false) -> void:
	if _plugin:
		_plugin.request_permission(provisional)

func get_permission_status() -> String:
	if _plugin:
		return _plugin.get_permission_status()
	return "unsupported"

func get_token() -> void:
	if _plugin:
		_plugin.get_token()

func delete_token() -> void:
	if _plugin:
		_plugin.delete_token()

func subscribe_to_topic(topic: String) -> void:
	if _plugin:
		_plugin.subscribe_to_topic(topic)

func unsubscribe_from_topic(topic: String) -> void:
	if _plugin:
		_plugin.unsubscribe_from_topic(topic)
