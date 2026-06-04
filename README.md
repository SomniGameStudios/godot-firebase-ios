# godot-firebase-ios

Firebase plugin for Godot 4 on iOS, implemented as a [GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html) using [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) — similar in approach to [GodotApplePlugins](https://github.com/migueldeicaza/GodotApplePlugins).

Designed to work alongside [godot-firebase-android](https://github.com/SomniGameStudios/godot-firebase-android), exposing the same API on both platforms for a consistent cross-platform experience.

---

## Features

**Authentication**
- Anonymous Sign-In
- Google Sign-In
- Apple Sign-In
- Email/Password Sign-In and user creation
- Auth state listener
- Account linking (Google, Apple)
- Delete user
- Firebase Auth Emulator support

**Cloud Firestore**
- Add, set, get, update, delete documents
- Get all documents in a collection
- Queries with filters, ordering, and limits
- Batched writes and transactions
- Real-time document listeners
- Firestore Emulator support

**Remote Config**
- Fetch, activate, and fetch-and-activate
- Typed getters (string, bool, int, float, JSON)
- Default values
- Real-time config update listener
- Value source and fetch status introspection

**Analytics**
- Log custom and predefined events with parameters
- User properties and user ID
- Default event parameters
- Consent management (ad and analytics storage)
- Session timeout configuration

---

## Documentation

**[somnigamestudios.github.io/godot-firebase-ios](https://somnigamestudios.github.io/godot-firebase-ios)**

Full installation guide, API reference, and examples.

---

## Dependencies

This plugin does **not** bundle the SwiftGodot runtime. It depends on the shared
`SwiftGodotRuntime` framework provided by the
[`GodotApplePluginsRuntime`](https://github.com/migueldeicaza/GodotApplePlugins)
addon.

Install `GodotApplePluginsRuntime` into your project's `addons/` folder
alongside this plugin — even if you do not use any other GodotApplePlugins
addon. The `.gdextension` manifest declares it as a native iOS dependency at
`res://addons/GodotApplePluginsRuntime/bin/SwiftGodotRuntime.xcframework`, so
Godot embeds it in the iOS export.

Both this plugin and the `GodotApplePluginsRuntime` build must be compiled
against the **same SwiftGodot revision**, or the iOS app will fail to launch
with Swift symbol-not-found errors. This plugin is pinned to the SwiftGodot
revision in [`GodotFirebaseiOS/Package.swift`](GodotFirebaseiOS/Package.swift)
(currently `ead7bffc9546c1740678a36096282e1a811b7da6`). Use a
`GodotApplePluginsRuntime` release built from the same revision.

---

## Requirements

| Tool | Minimum |
|------|---------|
| Godot | 4.6.1+ |
| Xcode | 15+ |
| iOS deployment target | 17+ |
| macOS (build machine) | 14+ |

## Development & Building

To build the plugin from source, you need macOS with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed.

1. **Setup dependencies**:
   ```bash
   make setup
   ```
   This will download the required pre-built Firebase SDK binaries and generate the Xcode project `GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj`.

2. **Build the framework**:
   ```bash
   make build
   ```
   This compiles the plugin for both iOS Device and iOS Simulator configurations, packages them into a universal `GodotFirebaseiOS.xcframework`, and copies the final GDExtension files and Firebase dependencies into the `demo/addons/GodotFirebaseiOS/` directory.

3. **Vendor output into the main app project**:
   Copy the compiled addon folder `demo/addons/GodotFirebaseiOS/` into your main Godot project's `addons/` directory:
   ```bash
   cp -R demo/addons/GodotFirebaseiOS/ <path-to-your-project>/addons/
   ```

---

## License

MIT — see [LICENSE](LICENSE).
