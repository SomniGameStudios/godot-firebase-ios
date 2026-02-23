extends Node

var auth = preload("res://addons/GodotFirebaseiOS/modules/Auth.gd").new()

func _ready() -> void:
	if ClassDB.class_exists(&"FirebaseAuthPlugin"):
		var _plugin = ClassDB.instantiate(&"FirebaseAuthPlugin")

		auth._plugin = _plugin
		auth._connect_signals()
		auth.initialize()
	else:
		if not OS.has_feature("editor"):
			printerr("GodotFirebaseiOS plugin not found!")
		return
