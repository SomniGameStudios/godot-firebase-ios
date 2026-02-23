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

## Setup

1. Download the latest release zip from [Releases](https://github.com/SomniGameStudios/godot-firebase-ios/releases).
2. Extract `addons/GodotFirebaseiOS/` into your project's `addons/` folder.
3. Enable the plugin in **Project → Project Settings → Plugins**. The `FirebaseIOS` autoload is registered automatically.
4. Place your `GoogleService-Info.plist` in `addons/GodotFirebaseiOS/`.

## Requirements

- Godot 4.4+
- iOS deployment target 17+
- Xcode 15+ and macOS 14+ (build machine)

## Cross-Platform (iOS + Android)

This plugin mirrors the API of [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid). Both expose the same Auth API, making it straightforward to target both platforms from a single codebase.

See the [Cross-Platform](cross-platform-wrapper) page for a unified wrapper example.

## License

MIT — [Somni Game Studios](https://github.com/SomniGameStudios)
