extends Control

@onready var output: RichTextLabel = %OutputPanel
@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput

func _ready() -> void:
	FirebaseIOS.auth.auth_success.connect(_on_auth_success)
	FirebaseIOS.auth.auth_failure.connect(_on_auth_failure)
	FirebaseIOS.auth.sign_out_success.connect(_on_sign_out_success)
	FirebaseIOS.auth.link_with_google_success.connect(_on_link_with_google_success)
	FirebaseIOS.auth.link_with_google_failure.connect(_on_link_with_google_failure)
	FirebaseIOS.auth.link_with_apple_success.connect(_on_link_with_apple_success)
	FirebaseIOS.auth.link_with_apple_failure.connect(_on_link_with_apple_failure)
	FirebaseIOS.auth.user_deleted.connect(_on_user_deleted)
	FirebaseIOS.auth.create_user_success.connect(_on_create_user_success)
	FirebaseIOS.auth.create_user_failure.connect(_on_create_user_failure)
	FirebaseIOS.auth.password_reset_success.connect(_on_password_reset_success)
	FirebaseIOS.auth.password_reset_failure.connect(_on_password_reset_failure)
	FirebaseIOS.auth.auth_state_changed.connect(_on_auth_state_changed)
	FirebaseIOS.auth.id_token_result.connect(_on_id_token_result)
	FirebaseIOS.auth.id_token_error.connect(_on_id_token_error)
	FirebaseIOS.auth.profile_updated.connect(_on_profile_updated)
	FirebaseIOS.auth.profile_update_failure.connect(_on_profile_update_failure)

	_log("platform", "iOS")

# --- Signal handlers ---

func _on_auth_success(user_data: Dictionary) -> void:
	_log("auth_success", JSON.stringify(user_data))

func _on_auth_failure(error_message: String) -> void:
	_log("auth_failure", error_message)

func _on_sign_out_success(success: bool) -> void:
	_log("sign_out_success", str(success))

func _on_link_with_google_success(user_data: Dictionary) -> void:
	_log("link_with_google_success", JSON.stringify(user_data))

func _on_link_with_google_failure(error_message: String) -> void:
	_log("link_with_google_failure", error_message)

func _on_link_with_apple_success(user_data: Dictionary) -> void:
	_log("link_with_apple_success", JSON.stringify(user_data))

func _on_link_with_apple_failure(error_message: String) -> void:
	_log("link_with_apple_failure", error_message)

func _on_user_deleted(success: bool) -> void:
	_log("user_deleted", str(success))

func _on_create_user_success(user_data: Dictionary) -> void:
	_log("create_user_success", JSON.stringify(user_data))

func _on_create_user_failure(error_message: String) -> void:
	_log("create_user_failure", error_message)

func _on_password_reset_success(success: bool) -> void:
	_log("password_reset_success", str(success))

func _on_password_reset_failure(error_message: String) -> void:
	_log("password_reset_failure", error_message)

func _on_auth_state_changed(signed_in: bool, user_data: Dictionary) -> void:
	_log("auth_state_changed", "signed_in=%s data=%s" % [signed_in, JSON.stringify(user_data)])

func _on_id_token_result(token: String) -> void:
	_log("id_token", token.substr(0, 50) + "..." if token.length() > 50 else token)

func _on_id_token_error(error_message: String) -> void:
	_log("id_token_error", error_message)

func _on_profile_updated(success: bool) -> void:
	_log("profile_updated", str(success))

func _on_profile_update_failure(error_message: String) -> void:
	_log("profile_update_failure", error_message)

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

# --- Sign-in ---

func _on_sign_in_anonymous_pressed() -> void:
	_log("action", "Signing in anonymously...")
	FirebaseIOS.auth.sign_in_anonymously()

func _on_sign_in_google_pressed() -> void:
	_log("action", "Signing in with Google...")
	FirebaseIOS.auth.sign_in_with_google()

func _on_link_google_pressed() -> void:
	_log("action", "Linking with Google...")
	FirebaseIOS.auth.link_anonymous_with_google()

func _on_sign_in_apple_pressed() -> void:
	_log("action", "Signing in with Apple...")
	FirebaseIOS.auth.sign_in_with_apple()

func _on_link_apple_pressed() -> void:
	_log("action", "Linking with Apple...")
	FirebaseIOS.auth.link_with_apple()

# --- Email/Password ---

func _on_create_account_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	_log("action", "Creating account for '%s'..." % email)
	FirebaseIOS.auth.create_user_with_email(email, password)

func _on_sign_in_email_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	_log("action", "Signing in with email '%s'..." % email)
	FirebaseIOS.auth.sign_in_with_email(email, password)

func _on_reset_password_pressed() -> void:
	var email = email_input.text
	_log("action", "Sending password reset to '%s'..." % email)
	FirebaseIOS.auth.send_password_reset_email(email)

# --- Query ---

func _on_get_user_pressed() -> void:
	var user = FirebaseIOS.auth.get_current_user_data()
	_log("get_current_user_data", JSON.stringify(user) if not user.is_empty() else "(no user)")

func _on_get_uid_pressed() -> void:
	var user = FirebaseIOS.auth.get_current_user_data()
	var uid: String = user.get("uid", "")
	_log("uid", uid if uid else "(no uid)")

func _on_is_signed_in_pressed() -> void:
	_log("is_signed_in", str(FirebaseIOS.auth.is_signed_in()))

func _on_is_anonymous_pressed() -> void:
	var user = FirebaseIOS.auth.get_current_user_data()
	_log("is_anonymous", str(user.get("isAnonymous", false)))

# --- User Management ---

func _on_update_profile_pressed() -> void:
	_log("action", "Updating profile display name to 'TestUser'...")
	FirebaseIOS.auth.update_profile("TestUser", "")

func _on_send_verification_pressed() -> void:
	_log("action", "Sending email verification...")
	FirebaseIOS.auth.send_email_verification()

func _on_reload_user_pressed() -> void:
	_log("action", "Reloading user data...")
	FirebaseIOS.auth.reload_user()

func _on_get_id_token_pressed() -> void:
	_log("action", "Getting ID token...")
	FirebaseIOS.auth.get_id_token(false)

# --- Auth State Listener ---

func _on_start_state_listener_pressed() -> void:
	_log("action", "Starting auth state listener...")
	FirebaseIOS.auth.add_auth_state_listener()

func _on_stop_state_listener_pressed() -> void:
	_log("action", "Stopping auth state listener")
	FirebaseIOS.auth.remove_auth_state_listener()

# --- Sign-out / Delete ---

func _on_sign_out_pressed() -> void:
	_log("action", "Signing out...")
	FirebaseIOS.auth.sign_out()

func _on_delete_user_pressed() -> void:
	_log("action", "Deleting current user...")
	FirebaseIOS.auth.delete_current_user()

# --- Utility ---

func _on_clear_output_pressed() -> void:
	output.text = ""
