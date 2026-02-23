#!/bin/bash

# GodotFirebaseiOS Build and Copy Script
# Builds the framework and copies it to demo/addons

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../"
ADDON_PATH="$PROJECT_ROOT/demo/addons/GodotFirebaseiOS"
BUILD_PATH="$SCRIPT_DIR/.build/xcodebuild"

# Default to Debug, allow Release with 'r' or 'release' parameter
CONFIGURATION="Debug"
if [[ "$1" == "r" || "$1" == "release" ]]; then
  CONFIGURATION="Release"
fi

echo "🔨 Building GodotFirebaseiOS ($CONFIGURATION)..."
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
  CODE_SIGNING_REQUIRED=NO

echo "📋 Locating built framework..."
FRAMEWORK_SOURCE="$BUILD_PATH/Build/Products/$CONFIGURATION-iphoneos/PackageFrameworks/GodotFirebaseiOS.framework"

if [ ! -d "$FRAMEWORK_SOURCE" ]; then
  echo "❌ Error: Framework not found at $FRAMEWORK_SOURCE"
  exit 1
fi

echo "🗑️  Removing old framework..."
rm -rf "$ADDON_PATH/GodotFirebaseiOS.framework"

echo "📦 Copying new framework..."
cp -r "$FRAMEWORK_SOURCE" "$ADDON_PATH/"

echo "✅ Done! Framework updated at $ADDON_PATH/GodotFirebaseiOS.framework"
