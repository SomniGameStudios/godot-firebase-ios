@tool
extends EditorPlugin

const AUTOLOAD_NAME := "FirebaseIOS"
const AUTOLOAD_PATH := "res://addons/GodotFirebaseiOS/FirebaseIOS.gd"

const PbxprojService := preload("res://addons/GodotFirebaseiOS/pbxproj_service.gd")

var export_plugin: IOSExportPlugin

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)

func _enter_tree() -> void:
	export_plugin = IOSExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class IOSExportPlugin extends EditorExportPlugin:
	var _export_path := ""
	var _is_ios := false

	func _get_name() -> String:
		return "GodotFirebaseiOS"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformIOS

	func _export_begin(
		features: PackedStringArray, _is_debug: bool, path: String, _flags: int
	) -> void:
		_export_path = path
		_is_ios = features.has("ios")
		if not _is_ios:
			return
		const PLIST_PATH := "res://addons/GodotFirebaseiOS/GoogleService-Info.plist"
		if not FileAccess.file_exists(PLIST_PATH):
			push_warning(
				"GodotFirebaseiOS: GoogleService-Info.plist not found at " + PLIST_PATH
				+ ". Firebase will fail to initialize. Place GoogleService-Info.plist in the addon."
			)
			return
		add_ios_bundle_file(PLIST_PATH)
		var reversed_client_id := _extract_reversed_client_id(PLIST_PATH)
		if reversed_client_id.is_empty():
			push_warning(
				"GodotFirebaseiOS: REVERSED_CLIENT_ID not found in plist. Google Sign-In will crash."
			)
			return
		add_ios_plist_content(_make_url_scheme_plist(reversed_client_id))
		add_ios_plist_content(_make_fcm_plist())

	func _export_end() -> void:
		if not _is_ios or _export_path.is_empty():
			return

		var export_dir := _export_path.get_base_dir()
		_defer_pbxproj_patch.call_deferred(export_dir)

	func _defer_pbxproj_patch(export_dir: String) -> void:
		_patch_xcodeproj(export_dir)

	func _patch_xcodeproj(export_dir: String) -> void:
		var project_name := _export_path.get_file().get_basename()
		var pbxproj_path := export_dir.path_join(project_name + ".xcodeproj/project.pbxproj")

		if FileAccess.file_exists(pbxproj_path):
			PbxprojService.patch(pbxproj_path)
			return

		var dir := DirAccess.open(export_dir)
		if not dir:
			push_warning("GodotFirebaseiOS: Could not open export directory: %s" % export_dir)
			return

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".xcodeproj"):
				var found_path := export_dir.path_join(file_name).path_join("project.pbxproj")
				if FileAccess.file_exists(found_path):
					PbxprojService.patch(found_path)
				else:
					push_warning("GodotFirebaseiOS: project.pbxproj not found at: %s" % found_path)
				break
			file_name = dir.get_next()

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

	func _make_fcm_plist() -> String:
		return """<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
<key>UIBackgroundModes</key>
<array>
	<string>remote-notification</string>
</array>
<key>FirebaseMessagingAutoInitEnabled</key>
<false/>"""
