# godot-firebase-ios

Firebase plugin for Godot 4 on iOS, implemented as a [GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html) using [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) — similar in approach to [GodotApplePlugins](https://github.com/migueldeicaza/GodotApplePlugins).

Designed to work alongside [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid), exposing the same API on both platforms for a consistent cross-platform experience.

---

## Features

**Authentication**
- Anonymous Sign-In
- Google Sign-In
- Apple Sign-In
- Account linking (Google, Apple)
- Delete user
- Firebase Auth Emulator support

**Cloud Firestore** _(WIP)_
- Add, set, get, update, delete documents
- Get all documents in a collection
- Real-time document listeners
- Firestore Emulator support

---

## Documentation

**[somnigamestudios.github.io/godot-firebase-ios](https://somnigamestudios.github.io/godot-firebase-ios)**

Full installation guide, API reference, and examples.

---

## Requirements

| Tool | Minimum |
|------|---------|
| Godot | 4.4+ |
| Xcode | 15+ |
| iOS deployment target | 17+ |
| macOS (build machine) | 14+ |

---

## License

MIT — see [LICENSE](LICENSE).
