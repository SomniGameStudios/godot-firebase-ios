#!/bin/bash

# GDExtension Stubs Generator
# Creates placeholder binaries for unsupported platforms to silence Godot Editor errors.

set -e

STUB_SRC="scripts/stub.c"
DEST_DIR="$1"

if [ -z "$DEST_DIR" ]; then
    echo "❌ Error: No destination directory provided."
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "📦 Generating GDExtension stubs in $DEST_DIR..."

# 1. macOS stub (Universal dylib for Intel and Apple Silicon)
clang -shared -target x86_64-apple-macos11.0 "$STUB_SRC" -o "$DEST_DIR/libstub_macos_x86.dylib" || true
clang -shared -target arm64-apple-macos11.0 "$STUB_SRC" -o "$DEST_DIR/libstub_macos_arm.dylib" || true

# Merge architectures into a single Universal binary
lipo -create "$DEST_DIR/libstub_macos_x86.dylib" "$DEST_DIR/libstub_macos_arm.dylib" -output "$DEST_DIR/libstub_macos.dylib" 2>/dev/null || 
cp "$DEST_DIR/libstub_macos_x86.dylib" "$DEST_DIR/libstub_macos.dylib"

# Cleanup temporary architecture-specific files
rm "$DEST_DIR/libstub_macos_x86.dylib" "$DEST_DIR/libstub_macos_arm.dylib" 2>/dev/null || true

# 2. Android stub (Shared library)
# Note: Using system gcc as a fallback placeholder
gcc -shared "$STUB_SRC" -o "$DEST_DIR/libstub_android.so" 2>/dev/null || touch "$DEST_DIR/libstub_android.so"

# 3. Windows stub (Empty DLL placeholder)
touch "$DEST_DIR/stub.dll"

echo "✅ Stubs generated successfully."
