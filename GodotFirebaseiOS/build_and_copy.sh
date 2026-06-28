#!/bin/bash

# GodotFirebaseiOS Build and Copy Script
# Builds the iOS framework and prepares the addon folder with stubs for cross-platform support.

set -e  # Exit on error

# --- Configuration ---

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
ADDON_PATH="$PROJECT_ROOT/demo/addons/GodotFirebaseiOS"
BUILD_PATH="$SCRIPT_DIR/.build/xcodebuild"

# OPTIONAL code-signing identity for the xcframework. By default the framework ships
# UNSIGNED: the Godot iOS export plugin injects a codesign build phase into the exported
# Xcode project, so the consuming app signs the framework with its own active identity at
# build/archive time — resolving ITMS-91065 automatically, with no manual step required.
#
# Set SIGN_IDENTITY only to PRE-sign the binary here instead — e.g. for a headless/CI
# export pipeline that does not run the editor export plugin. The host app re-signs the
# binary for distribution either way. Left empty so no identity is committed:
#   SIGN_IDENTITY="Apple Development: you@example.com (TEAMID)" ./build_and_copy.sh release
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

# Default to Debug, allow Release with 'r' or 'release' parameter
CONFIGURATION="Debug"
if [[ "$1" == "r" || "$1" == "release" ]]; then
  CONFIGURATION="Release"
fi


# --- iOS Build ---

echo "🔨 Building GodotFirebaseiOS ($CONFIGURATION) for iOS..."
cd "$SCRIPT_DIR"

PRODUCTS_DIR="$BUILD_PATH/Build/Products/$CONFIGURATION-iphoneos"
XCFRAMEWORK_OUT="$BUILD_PATH/GodotFirebaseiOS.xcframework"

locate_framework() {
  local fw
  for dir in "$PRODUCTS_DIR" "$PRODUCTS_DIR/PackageFrameworks"; do
    fw="$dir/GodotFirebaseiOS.framework"
    [ -f "$fw/GodotFirebaseiOS" ] && echo "$fw" && return 0
  done
  return 1
}

# SwiftGodot's 'Generator' host-tool target intermittently fails to resolve its SwiftSyntax
# dependency when the scheme is built for an iOS destination (an explicit-module race on the
# CI toolchain). That makes xcodebuild exit non-zero and can abort before our framework
# binary is linked — but it is flaky, so a retry succeeds. Our framework target itself is
# fine. So: build; if the framework BINARY is missing, retry. We tolerate a non-zero exit
# only when the binary was actually produced (the Generator failure is benign in that case).
MAX_ATTEMPTS=3
BUILD_STATUS=0
FRAMEWORK_SOURCE=""
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  echo "🔁 xcodebuild attempt $attempt/$MAX_ATTEMPTS..."
  set +e
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
    DEBUG_INFORMATION_FORMAT="dwarf"
  BUILD_STATUS=$?
  set -e
  FRAMEWORK_SOURCE="$(locate_framework)" && break
  echo "⚠️  Framework binary missing after attempt $attempt (xcodebuild exited $BUILD_STATUS)."
done

FRAMEWORK_BINARY="$FRAMEWORK_SOURCE/GodotFirebaseiOS"

echo "📋 Locating built frameworks..."
if [ ! -f "$FRAMEWORK_BINARY" ]; then
  echo "❌ Error: framework binary not found after $MAX_ATTEMPTS attempts (last xcodebuild exit $BUILD_STATUS)"
  echo "   Searched:"
  echo "     $PRODUCTS_DIR/GodotFirebaseiOS.framework/GodotFirebaseiOS"
  echo "     $PRODUCTS_DIR/PackageFrameworks/GodotFirebaseiOS.framework/GodotFirebaseiOS"
  exit 1
fi
if [ "$BUILD_STATUS" -ne 0 ]; then
  echo "⚠️  xcodebuild exited $BUILD_STATUS; the framework binary was produced (benign SwiftGodot 'Generator' host-tool failure). Continuing."
fi
echo "   Found: $FRAMEWORK_SOURCE"

# NOTE: No PrivacyInfo.xcprivacy is embedded here. Privacy declaration is the
# consuming app's responsibility — the app's own privacy manifest must declare the
# required-reason APIs that the statically-linked Firebase code uses (UserDefaults,
# FileTimestamp, SystemBootTime) plus any data it collects. See docs/PRIVACY.md.

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
xcodebuild -create-xcframework \
  -framework "$FRAMEWORK_SOURCE" \
  -framework "$SIM_FRAMEWORK_DIR" \
  -output "$XCFRAMEWORK_OUT"

# --- Code Signing (optional) ---
# By default the framework ships UNSIGNED and is signed by the consuming app's Xcode
# build: the Godot iOS export plugin injects a "Codesign GodotFirebaseiOS" build phase
# that signs it with the app's active identity at build/archive time (resolves ITMS-91065).
# Set SIGN_IDENTITY to PRE-sign the binary here instead (e.g. a headless/CI export that
# bypasses the editor plugin). Signing each slice then the bundle seals their origin.
if [ -n "$SIGN_IDENTITY" ]; then
  echo "🔏 Pre-signing xcframework with identity: $SIGN_IDENTITY"
  for SLICE_FW in "$XCFRAMEWORK_OUT"/*/GodotFirebaseiOS.framework; do
    echo "  • Signing $SLICE_FW"
    codesign --force --timestamp --sign "$SIGN_IDENTITY" "$SLICE_FW"
  done
  echo "  • Signing $XCFRAMEWORK_OUT"
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$XCFRAMEWORK_OUT"

  echo "🔎 Verifying device-slice signature..."
  codesign --verify --strict --verbose=2 "$XCFRAMEWORK_OUT/ios-arm64/GodotFirebaseiOS.framework"
  codesign -dvv "$XCFRAMEWORK_OUT/ios-arm64/GodotFirebaseiOS.framework" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier" || true
else
  echo "ℹ️  xcframework is UNSIGNED (by design)."
  echo "    The Godot iOS export plugin signs it automatically during the Xcode build/archive"
  echo "    (resolves ITMS-91065). To pre-sign here instead — e.g. for headless/CI export — run:"
  echo "      SIGN_IDENTITY=\"Apple Development: you@example.com (TEAMID)\" $0 $*"
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
