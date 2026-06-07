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
	const FRAMEWORKS_DIR := "res://addons/GodotFirebaseiOS/frameworks"

	var _export_path := ""

	const FIREBASE_FRAMEWORKS: PackedStringArray = [
		"AppAuth.xcframework",
		"AppCheckCore.xcframework",
		"FBLPromises.xcframework",
		"FirebaseABTesting.xcframework",
		"FirebaseAnalytics.xcframework",
		"FirebaseAppCheckInterop.xcframework",
		"FirebaseAuth.xcframework",
		"FirebaseAuthInterop.xcframework",
		"FirebaseCore.xcframework",
		"FirebaseCoreExtension.xcframework",
		"FirebaseCoreInternal.xcframework",
		"FirebaseDatabase.xcframework",
		"FirebaseFirestore.xcframework",
		"FirebaseFirestoreInternal.xcframework",
		"FirebaseInstallations.xcframework",
		"FirebaseMessaging.xcframework",
		"FirebaseMessagingInterop.xcframework",
		"FirebaseRemoteConfig.xcframework",
		"FirebaseRemoteConfigInterop.xcframework",
		"FirebaseSharedSwift.xcframework",
		"GTMAppAuth.xcframework",
		"GTMSessionFetcher.xcframework",
		"GoogleAppMeasurement.xcframework",
		"GoogleAppMeasurementIdentitySupport.xcframework",
		"GoogleDataTransport.xcframework",
		"GoogleSignIn.xcframework",
		"GoogleUtilities.xcframework",
		"RecaptchaInterop.xcframework",
		"absl.xcframework",
		"grpc.xcframework",
		"grpcpp.xcframework",
		"leveldb.xcframework",
		"nanopb.xcframework",
		"openssl_grpc.xcframework",
	]

	func _get_name() -> String:
		return "GodotFirebaseiOS"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformIOS

	func _export_begin(features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
		_export_path = path
		print("EXPORT FEATURES: ", features)
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
		add_ios_plist_content(_make_fcm_plist())
		add_ios_linker_flags("-ObjC")

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

	func _export_end() -> void:
		if _export_path.is_empty():
			return
		
		var project_name := _export_path.get_file().get_basename()
		var parent_dir := _export_path.get_base_dir()
		var dest_dir := parent_dir.path_join(project_name).path_join("frameworks")
		
		var src_abs := ProjectSettings.globalize_path(FRAMEWORKS_DIR)
		var dest_abs := ProjectSettings.globalize_path(dest_dir)
		
		# Ensure destination parent folder exists
		DirAccess.make_dir_recursive_absolute(dest_abs.get_base_dir())
		
		# Clean previous frameworks folder if exists to avoid nested copies
		if DirAccess.dir_exists_absolute(dest_abs):
			OS.execute("rm", ["-rf", dest_abs])

		var output := []
		var exit_code := OS.execute("cp", ["-R", src_abs, dest_abs], output, true)
		if exit_code != 0:
			push_warning("GodotFirebaseiOS: Failed to copy frameworks directory. Exit code: %d" % exit_code)
			return
		else:
			print("GodotFirebaseiOS: Copied frameworks to: ", dest_abs)

		_modify_pbxproj(_export_path)
		_export_path = ""

	func _modify_pbxproj(path: String) -> void:
		var pbxproj_path := path.path_join("project.pbxproj")
		if not FileAccess.file_exists(pbxproj_path):
			push_warning("GodotFirebaseiOS: project.pbxproj not found at " + pbxproj_path)
			return
		
		var file := FileAccess.open(pbxproj_path, FileAccess.READ)
		if not file:
			push_warning("GodotFirebaseiOS: Failed to open project.pbxproj for reading")
			return
		var content := file.get_as_text()
		file.close()

		var project_name := path.get_file().get_basename()
		var device_flags := ""
		var simulator_flags := ""

		for fw in FIREBASE_FRAMEWORKS:
			var fw_name_no_ext := fw.replace(".xcframework", "")
			device_flags += " -force_load \\\"$(PROJECT_DIR)/%s/frameworks/%s/ios-arm64/%s.framework/%s\\\"" % [project_name, fw, fw_name_no_ext, fw_name_no_ext]
			simulator_flags += " -force_load \\\"$(PROJECT_DIR)/%s/frameworks/%s/ios-arm64_x86_64-simulator/%s.framework/%s\\\"" % [project_name, fw, fw_name_no_ext, fw_name_no_ext]

		var target_str := "OTHER_LDFLAGS = \"$(LD_CLASSIC_$(XCODE_VERSION_ACTUAL)) -Wl,-U,_swift_entry_point -ObjC \";"
		var replacement_str := "\"OTHER_LDFLAGS[sdk=iphoneos*]\" = \"$(LD_CLASSIC_$(XCODE_VERSION_ACTUAL)) -Wl,-U,_swift_entry_point -ObjC -rdynamic %s\";\n\t\t\t\t\"OTHER_LDFLAGS[sdk=iphonesimulator*]\" = \"$(LD_CLASSIC_$(XCODE_VERSION_ACTUAL)) -Wl,-U,_swift_entry_point -ObjC -rdynamic %s\";" % [device_flags, simulator_flags]

		if content.contains(target_str):
			content = content.replace(target_str, replacement_str)
			var write_file := FileAccess.open(pbxproj_path, FileAccess.WRITE)
			if write_file:
				write_file.store_string(content)
				write_file.close()
				print("GodotFirebaseiOS: Successfully injected conditional force_load settings in project.pbxproj")
			else:
				push_warning("GodotFirebaseiOS: Failed to open project.pbxproj for writing")
		else:
			push_warning("GodotFirebaseiOS: Could not find OTHER_LDFLAGS pattern in project.pbxproj")
