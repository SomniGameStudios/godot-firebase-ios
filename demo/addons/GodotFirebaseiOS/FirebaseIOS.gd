extends Node

signal firebase_initialized
signal firebase_error(message: String)

var auth := preload("res://addons/GodotFirebaseiOS/modules/Auth.gd").new()
var firestore := preload("res://addons/GodotFirebaseiOS/modules/Firestore.gd").new()

func _ready() -> void:
	if not OS.has_feature("ios"):
		if OS.has_feature("editor"):
			print("GodotFirebaseiOS: Plugin standby in editor (only functional on iOS devices).")
		return

	# 1. Core — initialize Firebase first
	if ClassDB.class_exists(&"FirebaseCorePlugin"):
		var _core := ClassDB.instantiate(&"FirebaseCorePlugin")
		_core.connect("firebase_initialized", firebase_initialized.emit)
		_core.connect("firebase_error", firebase_error.emit)
		_core.initialize()
	else:
		printerr("GodotFirebaseiOS: FirebaseCorePlugin not found. Ensure the GDExtension is correctly exported and enabled for iOS.")
		return

	# 2. Auth module
	if ClassDB.class_exists(&"FirebaseAuthPlugin"):
		var _auth_plugin := ClassDB.instantiate(&"FirebaseAuthPlugin")
		auth._plugin = _auth_plugin
		auth._connect_signals()

	# 3. Firestore module
	if ClassDB.class_exists(&"FirebaseFirestorePlugin"):
		var _firestore_plugin := ClassDB.instantiate(&"FirebaseFirestorePlugin")
		firestore._plugin = _firestore_plugin
		firestore._connect_signals()
		firestore.initialize()
