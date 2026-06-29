# MIT License
#
# Copyright (c) 2026 Somni Game Studios
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

static func patch(path: String) -> void:
	var content := FileAccess.get_file_as_string(path)
	if content.is_empty():
		return

	if content.contains("FBDF105A0000000000000001"):
		return

	var phase_id := "FBDF105A0000000000000001"

	# Add PBXShellScriptBuildPhase section if not present
	if not content.contains("/* Begin PBXShellScriptBuildPhase section */"):
		content = content.replace(
			"/* End PBXCopyFilesBuildPhase section */",
			"/* End PBXCopyFilesBuildPhase section */\n\n"
			+ "/* Begin PBXShellScriptBuildPhase section */\n"
			+ "/* End PBXShellScriptBuildPhase section */"
		)

	# No section to host the phase: bail rather than reference an undefined phase
	# (a dangling buildPhases ref makes Xcode refuse to open the project).
	if not content.contains("/* End PBXShellScriptBuildPhase section */"):
		push_error(
			"GodotFirebaseiOS: PBXShellScriptBuildPhase section not found and could not "
			+ "be created in " + path + " — unexpected pbxproj layout; codesign phase NOT "
			+ "injected. Framework will ship unsigned (ITMS-91065)."
		)
		return

	# Inject our shell script build phase definition
	var shell_script := (
		"if [ -d \\\"$BUILT_PRODUCTS_DIR/"
		+ "$FRAMEWORKS_FOLDER_PATH/GodotFirebaseiOS.framework\\\" ]; then\\n"
		+ "  if [ -n \\\"${EXPANDED_CODE_SIGN_IDENTITY}\\\" ] "
		+ "&& [ \\\"${EXPANDED_CODE_SIGN_IDENTITY}\\\" != \\\"-\\\" ]; then\\n"
		+ "    codesign --force --timestamp --sign \\\"${EXPANDED_CODE_SIGN_IDENTITY}\\\" "
		+ "\\\"$BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH/GodotFirebaseiOS.framework\\\"\\n"
		+ "  else\\n"
		+ "    codesign --force --sign - "
		+ "\\\"$BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH/GodotFirebaseiOS.framework\\\"\\n"
		+ "  fi\\n"
		+ "fi\\n"
	)
	var phase_def := (
		"		"
		+ phase_id
		+ " /* Codesign GodotFirebaseiOS */ = {\n"
		+ "			isa = PBXShellScriptBuildPhase;\n"
		+ "			buildActionMask = 2147483647;\n"
		+ "			files = (\n"
		+ "			);\n"
		+ "			inputPaths = (\n"
		+ "			);\n"
		+ "			name = \"Codesign GodotFirebaseiOS\";\n"
		+ "			outputPaths = (\n"
		+ "			);\n"
		+ "			runOnlyForDeploymentPostprocessing = 0;\n"
		+ "			shellPath = /bin/sh;\n"
		+ "			shellScript = \"" + shell_script + "\";\n"
		+ "		};\n"
	)

	content = content.replace(
		"/* End PBXShellScriptBuildPhase section */",
		phase_def + "/* End PBXShellScriptBuildPhase section */"
	)

	# Inject into the native target's buildPhases array
	var injected := 0
	var target_index := content.find("isa = PBXNativeTarget;")
	while target_index != -1:
		var build_phases_start := content.find("buildPhases = (", target_index)
		if build_phases_start != -1:
			var build_phases_end := content.find(");", build_phases_start)
			if build_phases_end != -1:
				content = content.insert(
					build_phases_end,
					"				" + phase_id + " /* Codesign GodotFirebaseiOS */,\n"
				)
				injected += 1
		target_index = content.find("isa = PBXNativeTarget;", target_index + 1)

	# No target wired up: don't save an orphan phase that never runs; report instead.
	if injected == 0:
		push_error(
			"GodotFirebaseiOS: no PBXNativeTarget buildPhases array found in " + path
			+ " — codesign phase not wired to any target. Framework will ship unsigned "
			+ "(ITMS-91065)."
		)
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("GodotFirebaseiOS: Patched project.pbxproj with Codesign Run Script phase")
	else:
		push_error(
			"GodotFirebaseiOS: failed to open " + path + " for writing (error "
			+ str(FileAccess.get_open_error()) + ") — codesign phase NOT saved; "
			+ "framework will ship unsigned (ITMS-91065)."
		)
