extends Control

@onready var output: RichTextLabel = %OutputPanel

var _collection_enabled := true

func _ready() -> void:
	_log("platform", "iOS")

# --- Actions ---

func _on_log_event_pressed() -> void:
	_log("action", "Logging custom event 'test_event'...")
	FirebaseIOS.analytics.log_event("test_event", {
		"item_name": "sword_of_fire",
		"item_category": "weapons",
		"value": 100
	})
	_log("done", "Event logged (check Firebase Console)")

func _on_log_purchase_pressed() -> void:
	_log("action", "Logging purchase event...")
	FirebaseIOS.analytics.log_event("purchase", {
		"currency": "USD",
		"value": 9.99,
		"item_id": "gem_pack_100"
	})
	_log("done", "Purchase event logged")

func _on_set_user_id_pressed() -> void:
	_log("action", "Setting user ID to 'test_user_123'...")
	FirebaseIOS.analytics.set_user_id("test_user_123")
	_log("done", "User ID set")

func _on_set_user_property_pressed() -> void:
	_log("action", "Setting user property 'favorite_food' = 'pizza'...")
	FirebaseIOS.analytics.set_user_property("pizza", "favorite_food")
	_log("done", "User property set")

func _on_set_default_params_pressed() -> void:
	_log("action", "Setting default event parameters...")
	FirebaseIOS.analytics.set_default_event_parameters({
		"app_version": "1.0.0",
		"platform": "ios"
	})
	_log("done", "Default parameters set")

func _on_get_instance_id_pressed() -> void:
	var instance_id = FirebaseIOS.analytics.get_app_instance_id()
	_log("instance_id", instance_id if instance_id else "(empty)")

func _on_reset_analytics_pressed() -> void:
	_log("action", "Resetting analytics data...")
	FirebaseIOS.analytics.reset_analytics_data()
	_log("done", "Analytics data reset")

func _on_toggle_collection_pressed() -> void:
	_collection_enabled = not _collection_enabled
	_log("action", "Setting analytics collection to %s..." % str(_collection_enabled))
	FirebaseIOS.analytics.set_analytics_collection_enabled(_collection_enabled)
	_log("done", "Collection %s" % ("enabled" if _collection_enabled else "disabled"))

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
