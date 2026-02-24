extends Node

var auth := preload("res://addons/GodotFirebaseiOS/modules/Auth.gd").new()

func _ready() -> void:
	if not OS.has_feature("ios"):
		if OS.has_feature("editor"):
			print("GodotFirebaseiOS: Plugin standby in editor (only functional on iOS devices).")
		return

	if ClassDB.class_exists(&"FirebaseAuthPlugin"):
		var _plugin := ClassDB.instantiate(&"FirebaseAuthPlugin")
		auth._plugin = _plugin
		auth._connect_signals()
		auth.initialize()
	else:
		printerr("GodotFirebaseiOS: FirebaseAuthPlugin not found. Ensure the GDExtension is correctly exported and enabled for iOS.")
