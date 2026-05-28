#!/bin/bash

# GodotFirebaseiOS Build and Copy Script
# Builds the iOS framework and prepares the addon folder with stubs for cross-platform support.

set -e  # Exit on error

# --- Configuration ---

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
ADDON_PATH="$PROJECT_ROOT/demo/addons/GodotFirebaseiOS"
BUILD_PATH="$SCRIPT_DIR/.build/xcodebuild"

# Default to Debug, allow Release with 'r' or 'release' parameter
CONFIGURATION="Debug"
if [[ "$1" == "r" || "$1" == "release" ]]; then
  CONFIGURATION="Release"
fi


# --- iOS Build ---

echo "🔨 Building GodotFirebaseiOS ($CONFIGURATION) for iOS..."
cd "$SCRIPT_DIR"

xcodebuild \
  -scheme GodotFirebaseiOS \
  -sdk iphoneos \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$BUILD_PATH" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  DEBUG_INFORMATION_FORMAT="dwarf-with-dsym"

echo "📋 Locating built frameworks..."
FRAMEWORK_SOURCE="$BUILD_PATH/Build/Products/$CONFIGURATION-iphoneos/PackageFrameworks/GodotFirebaseiOS.framework"
XCFRAMEWORK_OUT="$BUILD_PATH/GodotFirebaseiOS.xcframework"
DSYM_SOURCE="$BUILD_PATH/Build/Products/$CONFIGURATION-iphoneos/PackageFrameworks/GodotFirebaseiOS.framework.dSYM"

if [ ! -d "$FRAMEWORK_SOURCE" ]; then
  echo "❌ Error: Framework not found at $FRAMEWORK_SOURCE"
  exit 1
fi

if [ ! -d "$DSYM_SOURCE" ]; then
  echo "⚠️ Warning: dSYM not found at $DSYM_SOURCE. Archive warnings may persist."
fi

# --- Create Simulator Stub ---

echo "🔨 Building Simulator Stub (arm64 + x86_64)..."
SIM_BUILD_DIR="$BUILD_PATH/simulator_stub"
SIM_FRAMEWORK_DIR="$SIM_BUILD_DIR/GodotFirebaseiOS.framework"
rm -rf "$SIM_BUILD_DIR"
mkdir -p "$SIM_FRAMEWORK_DIR"

IOSSIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)

# Compile arm64 stub
clang \
  -target arm64-apple-ios17.0-simulator \
  -isysroot "$IOSSIM_SDK" \
  -dynamiclib \
  -fvisibility=default \
  -install_name "@rpath/GodotFirebaseiOS.framework/GodotFirebaseiOS" \
  "$SCRIPT_DIR/scripts/stub.c" \
  -o "$SIM_BUILD_DIR/stub_arm64"

# Compile x86_64 stub
clang \
  -target x86_64-apple-ios17.0-simulator \
  -isysroot "$IOSSIM_SDK" \
  -dynamiclib \
  -fvisibility=default \
  -install_name "@rpath/GodotFirebaseiOS.framework/GodotFirebaseiOS" \
  "$SCRIPT_DIR/scripts/stub.c" \
  -o "$SIM_BUILD_DIR/stub_x86_64"

# Create universal binary for simulator framework
lipo -create "$SIM_BUILD_DIR/stub_arm64" "$SIM_BUILD_DIR/stub_x86_64" -output "$SIM_FRAMEWORK_DIR/GodotFirebaseiOS"

# Create simulator Info.plist
cat << 'EOF' > "$SIM_FRAMEWORK_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>GodotFirebaseiOS</string>
	<key>CFBundleIdentifier</key>
	<string>godotfirebaseios.GodotFirebaseiOS</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>GodotFirebaseiOS</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>iPhoneSimulator</string>
	</array>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>DTPlatformName</key>
	<string>iphonesimulator</string>
	<key>MinimumOSVersion</key>
	<string>17.0</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
		<integer>2</integer>
	</array>
</dict>
</plist>
EOF

# --- Create XCFramework ---

echo "📦 Creating XCFramework..."
rm -rf "$XCFRAMEWORK_OUT"

# Plugin XCFramework containing both physical device framework and simulator stub framework
if [ -d "$DSYM_SOURCE" ]; then
  xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_SOURCE" \
    -debug-symbols "$(cd "$(dirname "$DSYM_SOURCE")" && pwd)/$(basename "$DSYM_SOURCE")" \
    -framework "$SIM_FRAMEWORK_DIR" \
    -output "$XCFRAMEWORK_OUT"
else
  xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_SOURCE" \
    -framework "$SIM_FRAMEWORK_DIR" \
    -output "$XCFRAMEWORK_OUT"
fi

# --- Addon Update ---

echo "📦 Updating addon folder..."

# Clean up old xcframeworks and copy the fresh one.
# SwiftGodotRuntime is intentionally not bundled — it is provided by the
# GodotApplePluginsRuntime addon (see README "Dependencies").
rm -rf "$ADDON_PATH/GodotFirebaseiOS.framework"
rm -rf "$ADDON_PATH/GodotFirebaseiOS.framework.dSYM"
rm -rf "$ADDON_PATH/GodotFirebaseiOS.xcframework"
rm -rf "$ADDON_PATH/SwiftGodotRuntime.xcframework"

cp -r "$XCFRAMEWORK_OUT" "$ADDON_PATH/"

echo "✅ Done! Addon updated at $ADDON_PATH"
