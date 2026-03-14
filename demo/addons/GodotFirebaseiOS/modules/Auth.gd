extends Node

signal auth_success(current_user_data: Dictionary)
signal auth_failure(error_message: String)
signal sign_out_success(success: bool)
signal user_deleted(success: bool)
signal link_with_google_success(current_user_data: Dictionary)
signal link_with_google_failure(error_message: String)
signal link_with_apple_success(current_user_data: Dictionary)
signal link_with_apple_failure(error_message: String)
signal create_user_success(current_user_data: Dictionary)
signal create_user_failure(error_message: String)
signal password_reset_success(success: bool)
signal password_reset_failure(error_message: String)
signal auth_state_changed(signed_in: bool, current_user_data: Dictionary)
signal id_token_result(token: String)
signal id_token_error(error_message: String)
signal profile_updated(success: bool)
signal profile_update_failure(error_message: String)

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
	_plugin.connect("create_user_success", create_user_success.emit)
	_plugin.connect("create_user_failure", create_user_failure.emit)
	_plugin.connect("password_reset_success", password_reset_success.emit)
	_plugin.connect("password_reset_failure", password_reset_failure.emit)
	_plugin.connect("auth_state_changed", auth_state_changed.emit)
	_plugin.connect("id_token_result", id_token_result.emit)
	_plugin.connect("id_token_error", id_token_error.emit)
	_plugin.connect("profile_updated", profile_updated.emit)
	_plugin.connect("profile_update_failure", profile_update_failure.emit)

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

# Email/Password Auth

func create_user_with_email(email: String, password: String) -> void:
	if _plugin:
		_plugin.create_user_with_email(email, password)

func sign_in_with_email(email: String, password: String) -> void:
	if _plugin:
		_plugin.sign_in_with_email(email, password)

func send_password_reset_email(email: String) -> void:
	if _plugin:
		_plugin.send_password_reset_email(email)

# Auth State Listener

func add_auth_state_listener() -> void:
	if _plugin:
		_plugin.add_auth_state_listener()

func remove_auth_state_listener() -> void:
	if _plugin:
		_plugin.remove_auth_state_listener()

# ID Token

func get_id_token(force_refresh: bool = false) -> void:
	if _plugin:
		_plugin.get_id_token(force_refresh)

# Profile Management

func update_profile(display_name: String, photo_url: String = "") -> void:
	if _plugin:
		_plugin.update_profile(display_name, photo_url)

func update_password(new_password: String) -> void:
	if _plugin:
		_plugin.update_password(new_password)

func send_email_verification() -> void:
	if _plugin:
		_plugin.send_email_verification()

func reload_user() -> void:
	if _plugin:
		_plugin.reload_user()

func unlink_provider(provider_id: String) -> void:
	if _plugin:
		_plugin.unlink_provider(provider_id)

func reauthenticate_with_email(email: String, password: String) -> void:
	if _plugin:
		_plugin.reauthenticate_with_email(email, password)
