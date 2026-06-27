---
title: Home
layout: home
nav_order: 1
---

# Godot Firebase iOS

Firebase plugin for Godot 4 on iOS, implemented as a GDExtension using [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot).

Designed to work alongside [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid), exposing the same API on both platforms for a consistent cross-platform experience.

## Supported Features

- Authentication (Anonymous, Google, Apple, account linking)
- Cloud Firestore (CRUD, real-time listeners)
- Remote Config (fetch, activate, typed getters, real-time updates)
- Analytics (events, user properties, consent, session management)

## Setup

1. Download the latest release zip from [Releases](https://github.com/SomniGameStudios/godot-firebase-ios/releases).
2. Extract `addons/GodotFirebaseiOS/` into your project's `addons/` folder.
3. Install the shared SwiftGodot runtime: download [GodotApplePlugins](https://github.com/migueldeicaza/GodotApplePlugins/releases) and extract its `addons/GodotApplePluginsRuntime/` into your project's `addons/` folder. This plugin depends on it for the iOS export and does not bundle its own copy.
4. Enable the plugin in **Project → Project Settings → Plugins**. The `FirebaseIOS` autoload is registered automatically.
5. Place your `GoogleService-Info.plist` in `addons/GodotFirebaseiOS/`.
6. **Before submitting to the App Store**, handle two consumer responsibilities:
   - **Codesign** is handled automatically: Godot's export plugin automatically patches your Xcode project to inject a codesigning phase that signs the framework during compile time, resolving ITMS-91065.
   - **Declare** Firebase's required-reason API usage in your iOS export preset. See the [README](https://github.com/SomniGameStudios/godot-firebase-ios#using-the-plugin-in-your-app) and `docs/PRIVACY.md`.

> **Version match:** this plugin and `GodotApplePluginsRuntime` must be built against the same SwiftGodot revision, or the iOS app will crash at launch with Swift symbol errors. See the [README](https://github.com/SomniGameStudios/godot-firebase-ios#dependencies) for the pinned revision.

## Requirements

- Godot 4.4+
- iOS deployment target 17+
- Xcode 15+ and macOS 14+ (build machine)

## Cross-Platform (iOS + Android)

This plugin mirrors the API of [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid). Both expose the same Auth API, making it straightforward to target both platforms from a single codebase.

See the [Cross-Platform](cross-platform-wrapper) page for a unified wrapper example.

## License

MIT — [Somni Game Studios](https://github.com/SomniGameStudios)
