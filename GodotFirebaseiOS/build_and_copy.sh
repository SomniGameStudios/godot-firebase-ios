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

echo "📋 Locating built framework..."
FRAMEWORK_SOURCE="$BUILD_PATH/Build/Products/$CONFIGURATION-iphoneos/PackageFrameworks/GodotFirebaseiOS.framework"
DSYM_SOURCE="$BUILD_PATH/Build/Products/$CONFIGURATION-iphoneos/GodotFirebaseiOS.framework.dSYM"
XCFRAMEWORK_OUT="$BUILD_PATH/GodotFirebaseiOS.xcframework"

if [ ! -d "$FRAMEWORK_SOURCE" ]; then
  echo "❌ Error: Framework not found at $FRAMEWORK_SOURCE"
  exit 1
fi

if [ ! -d "$DSYM_SOURCE" ]; then
  echo "⚠️ Warning: dSYM not found at $DSYM_SOURCE. Archive warnings may persist."
fi

# --- Create XCFramework ---

echo "📦 Creating XCFramework..."
rm -rf "$XCFRAMEWORK_OUT"

if [ -d "$DSYM_SOURCE" ]; then
  xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_SOURCE" \
    -debug-symbols "$(cd "$(dirname "$DSYM_SOURCE")" && pwd)/$(basename "$DSYM_SOURCE")" \
    -output "$XCFRAMEWORK_OUT"
else
  xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_SOURCE" \
    -output "$XCFRAMEWORK_OUT"
fi

# --- Addon Update ---

echo "📦 Updating addon folder..."

# Clean up old xcframework/framework and copy the fresh xcframework
rm -rf "$ADDON_PATH/GodotFirebaseiOS.framework"
rm -rf "$ADDON_PATH/GodotFirebaseiOS.framework.dSYM"
rm -rf "$ADDON_PATH/GodotFirebaseiOS.xcframework"

cp -r "$XCFRAMEWORK_OUT" "$ADDON_PATH/"

echo "✅ Done! Addon updated at $ADDON_PATH"
