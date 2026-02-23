---
title: Home
layout: home
nav_order: 1
---

# Godot Firebase iOS

Firebase Authentication plugin for Godot 4 on iOS, built with [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) GDExtension.

Mirrors the API of [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid) for a consistent cross-platform experience.

---

## Features

- Anonymous Sign-In
- Google Sign-In
- Apple Sign-In
- Account linking (Google, Apple)
- Delete user
- Firebase Auth Emulator support

---

## Installation

### From Release (Recommended)

1. Download the latest release zip from [Releases](https://github.com/SomniGameStudios/godot-firebase-ios/releases).
2. Extract `addons/GodotFirebaseiOS/` into your Godot project's `addons/` folder.
3. Enable the plugin in **Project → Project Settings → Plugins**. The `FirebaseIOS` autoload is registered automatically.
4. Place your `GoogleService-Info.plist` in `addons/GodotFirebaseiOS/`.

### Build from Source

```bash
cd GodotFirebaseiOS
./build_and_copy.sh r   # Release build
```

See [GodotFirebaseiOS/README.md](https://github.com/SomniGameStudios/godot-firebase-ios/blob/main/GodotFirebaseiOS/README.md) for full Xcode instructions.

---

## Requirements

| Tool | Minimum Version |
|------|----------------|
| Xcode | 15+ |
| Swift | 5.9+ |
| iOS deployment target | 17+ |
| macOS (build machine) | 14+ |
| Godot | 4.4+ |

---

## Cross-Platform (iOS + Android)

This plugin mirrors the API of [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid). Both expose the same Auth API, making it straightforward to write a thin wrapper that delegates to the correct platform at runtime.

See [`docs/cross-platform-wrapper.md`](https://github.com/SomniGameStudios/godot-firebase-ios/blob/main/docs/cross-platform-wrapper.md) in the repository for an example.

---

## License

MIT — [Somni Game Studios](https://github.com/SomniGameStudios)
