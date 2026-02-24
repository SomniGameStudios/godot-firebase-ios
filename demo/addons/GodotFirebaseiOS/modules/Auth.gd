extends Node

signal auth_success(current_user_data: Dictionary)
signal auth_failure(error_message: String)
signal sign_out_success(success: bool)
signal user_deleted(success: bool)
signal link_with_google_success(current_user_data: Dictionary)
signal link_with_google_failure(error_message: String)
signal link_with_apple_success(current_user_data: Dictionary)
signal link_with_apple_failure(error_message: String)

var _plugin: Object

func _connect_signals():
	if not _plugin:
		return
	_plugin.connect("auth_success", auth_success.emit)
	_plugin.connect("auth_failure", auth_failure.emit)
	_plugin.connect("sign_out_success", sign_out_success.emit)
	_plugin.connect("user_deleted", user_deleted.emit)
	_plugin.connect("link_with_google_success", link_with_google_success.emit)
	_plugin.connect("link_with_google_failure", link_with_google_failure.emit)
	_plugin.connect("link_with_apple_success", link_with_apple_success.emit)
	_plugin.connect("link_with_apple_failure", link_with_apple_failure.emit)

func use_emulator(host: String, port: int) -> void:
	if _plugin:
		_plugin.use_emulator(host, port)

func sign_in_anonymously() -> void:
	if _plugin:
		_plugin.sign_in_anonymously()

func sign_in_with_google() -> void:
	if _plugin:
		_plugin.sign_in_with_google()

func sign_in_with_apple() -> void:
	if _plugin:
		_plugin.sign_in_with_apple()

func link_anonymous_with_google() -> void:
	if _plugin:
		_plugin.link_with_google()

func link_with_apple() -> void:
	if _plugin:
		_plugin.link_with_apple()

func sign_out() -> void:
	if _plugin:
		_plugin.sign_out()

func delete_current_user() -> void:
	if _plugin:
		_plugin.delete_current_user()

func is_signed_in() -> bool:
	var status := false
	if _plugin:
		status = _plugin.is_signed_in()
	return status

func get_current_user_data() -> Dictionary:
	var user_data: Dictionary
	if _plugin:
		user_data = _plugin.get_current_user_data()
	return user_data
