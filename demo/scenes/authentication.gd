extends Control

@onready var output: RichTextLabel = %OutputPanel

func _ready() -> void:
	FirebaseIOS.auth.auth_success.connect(_on_auth_success)
	FirebaseIOS.auth.auth_failure.connect(_on_auth_failure)
	FirebaseIOS.auth.sign_out_success.connect(_on_sign_out_success)
	FirebaseIOS.auth.link_with_google_success.connect(_on_link_with_google_success)
	FirebaseIOS.auth.link_with_google_failure.connect(_on_link_with_google_failure)
	FirebaseIOS.auth.link_with_apple_success.connect(_on_link_with_apple_success)
	FirebaseIOS.auth.link_with_apple_failure.connect(_on_link_with_apple_failure)
	FirebaseIOS.auth.user_deleted.connect(_on_user_deleted)

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
