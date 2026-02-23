@tool
extends EditorPlugin

const AUTOLOAD_NAME := "FirebaseIOS"
const AUTOLOAD_PATH := "res://addons/GodotFirebaseiOS/FirebaseIOS.gd"

var export_plugin: iOSExportPlugin

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)

func _enter_tree() -> void:
	export_plugin = iOSExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class iOSExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "GodotFirebaseiOS"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformIOS

	func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not features.has("ios"):
			return
		const PLIST_PATH := "res://addons/GodotFirebaseiOS/GoogleService-Info.plist"
		if not FileAccess.file_exists(PLIST_PATH):
			push_warning("GodotFirebaseiOS: GoogleService-Info.plist not found at " + PLIST_PATH + ". Firebase will fail to initialize. Place your GoogleService-Info.plist from the Firebase console into res://addons/GodotFirebaseiOS/")
			return
		add_ios_bundle_file(PLIST_PATH)
		var reversed_client_id := _extract_reversed_client_id(PLIST_PATH)
		if reversed_client_id.is_empty():
			push_warning("GodotFirebaseiOS: REVERSED_CLIENT_ID not found in GoogleService-Info.plist. Google Sign-In will crash.")
			return
		add_ios_plist_content(_make_url_scheme_plist(reversed_client_id))

	func _extract_reversed_client_id(plist_path: String) -> String:
		var parser := XMLParser.new()
		if parser.open(plist_path) != OK:
			return ""
		var found_key := false
		while parser.read() == OK:
			if parser.get_node_type() != XMLParser.NODE_TEXT:
				continue
			var text := parser.get_node_data().strip_edges()
			if text.is_empty():
				continue
			if text == "REVERSED_CLIENT_ID":
				found_key = true
			elif found_key:
				return text
		return ""

	func _make_url_scheme_plist(reversed_client_id: String) -> String:
		return """<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>%s</string>
		</array>
	</dict>
</array>""" % reversed_client_id
