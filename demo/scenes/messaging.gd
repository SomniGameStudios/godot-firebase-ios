extends Control

@onready var output: RichTextLabel = %OutputPanel

func _ready() -> void:
	FirebaseIOS.messaging.token_received.connect(_on_token_received)
	FirebaseIOS.messaging.notification_received.connect(_on_notification_received)
	FirebaseIOS.messaging.notification_opened.connect(_on_notification_opened)
	FirebaseIOS.messaging.permission_result.connect(_on_permission_result)
	FirebaseIOS.messaging.topic_subscribe_success.connect(_on_topic_subscribe_success)
	FirebaseIOS.messaging.topic_subscribe_failure.connect(_on_topic_subscribe_failure)
	FirebaseIOS.messaging.topic_unsubscribe_success.connect(_on_topic_unsubscribe_success)
	FirebaseIOS.messaging.topic_unsubscribe_failure.connect(_on_topic_unsubscribe_failure)
	FirebaseIOS.messaging.token_delete_success.connect(_on_token_delete_success)
	FirebaseIOS.messaging.token_delete_failure.connect(_on_token_delete_failure)

	_log("platform", "iOS")

# --- Signal handlers ---

func _on_token_received(token: String) -> void:
	_log("token_received", token)

func _on_notification_received(data: Dictionary) -> void:
	_log("notification_received", JSON.stringify(data))

func _on_notification_opened(data: Dictionary) -> void:
	_log("notification_opened", JSON.stringify(data))

func _on_permission_result(granted: bool) -> void:
	_log("permission_result", str(granted))

func _on_topic_subscribe_success(topic: String) -> void:
	_log("topic_subscribe_success", topic)

func _on_topic_subscribe_failure(message: String) -> void:
	_log("topic_subscribe_failure", message)

func _on_topic_unsubscribe_success(topic: String) -> void:
	_log("topic_unsubscribe_success", topic)

func _on_topic_unsubscribe_failure(message: String) -> void:
	_log("topic_unsubscribe_failure", message)

func _on_token_delete_success() -> void:
	_log("token_delete_success", "")

func _on_token_delete_failure(message: String) -> void:
	_log("token_delete_failure", message)

# --- Actions ---

func _on_configure_pressed() -> void:
	_log("action", "Configuring FCM...")
	FirebaseIOS.messaging.configure()

func _on_request_permission_pressed() -> void:
	_log("action", "Requesting permission...")
	FirebaseIOS.messaging.request_permission()

func _on_request_provisional_pressed() -> void:
	_log("action", "Requesting provisional permission...")
	FirebaseIOS.messaging.request_permission(true)

func _on_get_status_pressed() -> void:
	var status := FirebaseIOS.messaging.get_permission_status()
	_log("permission_status", status)

func _on_get_token_pressed() -> void:
	_log("action", "Getting FCM token...")
	FirebaseIOS.messaging.get_token()

func _on_delete_token_pressed() -> void:
	_log("action", "Deleting FCM token...")
	FirebaseIOS.messaging.delete_token()

func _on_subscribe_pressed() -> void:
	_log("action", "Subscribing to 'test_topic'...")
	FirebaseIOS.messaging.subscribe_to_topic("test_topic")

func _on_unsubscribe_pressed() -> void:
	_log("action", "Unsubscribing from 'test_topic'...")
	FirebaseIOS.messaging.unsubscribe_from_topic("test_topic")

# --- Logging ---

func _log(context: String, message: String) -> void:
	var t := Time.get_time_string_from_system()
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

func _on_clear_output_pressed() -> void:
	output.text = ""
