#!/bin/bash

# GodotFirebaseiOS Build and Copy Script
# Builds the iOS framework and prepares the addon folder with stubs for cross-platform support.

set -e  # Exit on error

# --- Configuration ---

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
ADDON_PATH="$PROJECT_ROOT/demo/addons/GodotFirebaseiOS"
BUILD_PATH="$SCRIPT_DIR/.build/xcodebuild"

# Code-signing identity for the xcframework. Apple requires the *distributor* of a
# repackaged third-party SDK to sign it (ITMS-91065), because we statically link
# Firebase (compiled from source) into this framework. App-level CodeSignOnCopy at
# the host app's archive step is NOT sufficient. Pass any valid Apple-issued signing
# identity (Apple Development is fine — the host app re-signs the binary for
# distribution). Left empty here on purpose so no production identity is committed:
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

FRAMEWORK_SOURCE="$BUILD_PATH/Build/Products/$CONFIGURATION-iphoneos/GodotFirebaseiOS.framework"
FRAMEWORK_BINARY="$FRAMEWORK_SOURCE/GodotFirebaseiOS"
XCFRAMEWORK_OUT="$BUILD_PATH/GodotFirebaseiOS.xcframework"

# SwiftGodot's 'Generator' host-tool target intermittently fails to resolve its SwiftSyntax
# dependency when the scheme is built for an iOS destination (an explicit-module race on the
# CI toolchain). That makes xcodebuild exit non-zero and can abort before our framework
# binary is linked — but it is flaky, so a retry succeeds. Our framework target itself is
# fine. So: build; if the framework BINARY is missing, retry. We tolerate a non-zero exit
# only when the binary was actually produced (the Generator failure is benign in that case).
MAX_ATTEMPTS=3
BUILD_STATUS=0
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
  [ -f "$FRAMEWORK_BINARY" ] && break
  echo "⚠️  Framework binary missing after attempt $attempt (xcodebuild exited $BUILD_STATUS)."
done

echo "📋 Locating built frameworks..."
if [ ! -f "$FRAMEWORK_BINARY" ]; then
  echo "❌ Error: framework binary not found at $FRAMEWORK_BINARY after $MAX_ATTEMPTS attempts (last xcodebuild exit $BUILD_STATUS)"
  exit 1
fi
if [ "$BUILD_STATUS" -ne 0 ]; then
  echo "⚠️  xcodebuild exited $BUILD_STATUS; the framework binary was produced (benign SwiftGodot 'Generator' host-tool failure). Continuing."
fi

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

# --- Code Signing ---
# Sign each framework slice (seals the binary + Info.plist + PrivacyInfo.xcprivacy),
# then sign the xcframework bundle so its origin can be verified. Required to satisfy
# App Store ITMS-91065 for the statically-linked Firebase SDK.
if [ -n "$SIGN_IDENTITY" ]; then
  echo "🔏 Signing xcframework with identity: $SIGN_IDENTITY"
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
  echo "⚠️  SIGN_IDENTITY not set — xcframework is UNSIGNED."
  echo "    The App Store will reject this build with ITMS-91065 (Missing signature)."
  echo "    Re-run with a signing identity, e.g.:"
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
