extends Control

@onready var output: RichTextLabel = %OutputPanel
@onready var key_input: LineEdit = %KeyInput

func _ready() -> void:
	FirebaseIOS.remote_config.fetch_completed.connect(_on_fetch_completed)
	FirebaseIOS.remote_config.activate_completed.connect(_on_activate_completed)
	FirebaseIOS.remote_config.config_updated.connect(_on_config_updated)

	_log("platform", "iOS")

# --- Signal handlers ---

func _on_fetch_completed(result: Dictionary) -> void:
	_log("fetch", "status=%s error=%s" % [result.get("status"), result.get("error", "")])

func _on_activate_completed(result: Dictionary) -> void:
	_log("activate", "status=%s error=%s" % [result.get("status"), result.get("error", "")])

func _on_config_updated(updated_keys: Array) -> void:
	_log("update", "keys=%s" % [JSON.stringify(updated_keys)])

# --- Actions ---

func _on_set_defaults_pressed() -> void:
	var defaults = {"welcome_message": "Hello!", "feature_enabled": false, "max_items": 10}
	_log("action", "Setting defaults: %s" % JSON.stringify(defaults))
	FirebaseIOS.remote_config.set_defaults(defaults)

func _on_set_dev_interval_pressed() -> void:
	_log("action", "Setting minimum fetch interval to 0 (dev mode)")
	FirebaseIOS.remote_config.set_minimum_fetch_interval(0)

func _on_fetch_pressed() -> void:
	_log("action", "Fetching remote config...")
	FirebaseIOS.remote_config.fetch()

func _on_activate_pressed() -> void:
	_log("action", "Activating fetched config...")
	FirebaseIOS.remote_config.activate()

func _on_fetch_and_activate_pressed() -> void:
	_log("action", "Fetching and activating...")
	FirebaseIOS.remote_config.fetch_and_activate()

func _on_get_value_pressed() -> void:
	var key = key_input.text
	if key.is_empty():
		_log("error", "Enter a key name first")
		return
	var str_val = FirebaseIOS.remote_config.get_string(key)
	var bool_val = FirebaseIOS.remote_config.get_bool(key)
	var int_val = FirebaseIOS.remote_config.get_int(key)
	var float_val = FirebaseIOS.remote_config.get_float(key)
	_log("value", "key='%s' string='%s' bool=%s int=%s float=%s" % [key, str_val, bool_val, int_val, float_val])

func _on_get_all_pressed() -> void:
	var all = FirebaseIOS.remote_config.get_all()
	_log("all", JSON.stringify(all))

func _on_listen_pressed() -> void:
	_log("action", "Listening for config updates...")
	FirebaseIOS.remote_config.listen_for_updates()

func _on_stop_listen_pressed() -> void:
	_log("action", "Stopped listening for config updates")
	FirebaseIOS.remote_config.stop_listening_for_updates()

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

func _on_clear_output_pressed() -> void:
	output.text = ""
