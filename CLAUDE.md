# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
./GodotFirebaseiOS/build_and_copy.sh        # Debug
./GodotFirebaseiOS/build_and_copy.sh r      # Release
```

Output framework is copied to `demo/addons/GodotFirebaseiOS/`. Requires macOS with Xcode 15+.

## Run the Demo

1. Place `GoogleService-Info.plist` in `demo/addons/GodotFirebaseiOS/`
2. Open `demo/` in Godot 4.4+
3. Export to a physical iOS device (required for Google Sign-In)

## Architecture

This plugin has a two-layer bridge: **Swift GDExtension → GDScript wrapper → game code**.

**Layer 1 — Swift plugins** (`GodotFirebaseiOS/Sources/GodotFirebaseiOS/`): Each Firebase module is a `@Godot`-annotated `RefCounted` subclass with `@Callable` methods and `@Signal` definitions. These are compiled into a `.framework` and registered in `GodotFirebaseiOS.swift` via `#initSwiftExtension`. Async Firebase SDK calls use `Task { @MainActor in }` to ensure signals emit on the main thread.

**Layer 2 — GDScript wrappers** (`demo/addons/GodotFirebaseiOS/modules/`): Thin wrappers (`Auth.gd`, `Firestore.gd`, etc.) that hold a reference to the Swift plugin object, forward all method calls with `if _plugin:` guards, and relay signals via `_connect_signals()`. These are composed into the `FirebaseIOS` autoload singleton (`FirebaseIOS.gd`), which instantiates each Swift class via `ClassDB.instantiate()` at runtime.

**Export plugin** (`export_plugin.gd`): Runs at iOS export time to inject `REVERSED_CLIENT_ID` URL scheme into `Info.plist` and embed `GoogleService-Info.plist` into the app bundle.

**Cross-platform stubs**: Non-iOS platforms use stub binaries (generated via `scripts/generate_stubs.sh`) so the Godot editor doesn't error when the native library isn't available.

## Adding a New Firebase Module

1. Create `Firebase<Name>Plugin.swift` — subclass `RefCounted`, use `@Godot`, `@Callable`, `@Signal` macros
2. Register it in `GodotFirebaseiOS.swift`'s `#initSwiftExtension` types array
3. Create `modules/<Name>.gd` — mirror signals, add `_connect_signals()`, forward methods with `if _plugin:` guards
4. Wire it up in `FirebaseIOS.gd` following the existing pattern (ClassDB.class_exists → instantiate → assign to module)
5. Update `GodotFirebaseiOS.gdextension` if needed

## API Design Priority

1. **Stay close to the official Firebase iOS SDK** — method names, parameters, and behavior should mirror the native Swift Firebase SDK as closely as possible within GDExtension constraints.
2. **Match [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid)** — as a secondary goal, keep the GDScript-facing API compatible so games can use the same interface on both platforms.

## Testing

No unit test suite. Validation is via the demo project scenes in `demo/scenes/`. All modules support Firebase Emulator Suite (`use_emulator()` methods). CI validates compilation only.

## CI/CD

- **build.yml** — PR validation on macOS-26
- **release.yml** — Manual trigger: builds release, zips addon, creates GitHub Release
- **docs.yml** — Auto-deploys Jekyll docs to GitHub Pages on push to main
