# GodotFirebaseiOS — Swift Package

Firebase Authentication plugin for Godot 4 on iOS, implemented as a SwiftGodot GDExtension.

See the [main README](../README.md) for installation and GDScript API reference.

---

## What This Package Does

Registers a `FirebaseAuthPlugin` class into Godot's ClassDB via SwiftGodot.
The class is instantiated at runtime by `FirebaseIOS.gd` (the autoload) on iOS
and exposes Firebase Authentication as `@Callable` functions and `@Signal` properties.

---

## Package Dependencies

| Package | Requirement | Resolved |
|---------|-------------|---------|
| [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) | pinned revision `61f258c` | — |
| [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) | >= 11.0.0 | 11.15.0 |
| [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) | >= 9.1.0 | 9.1.0 |

---

## Building the Framework

1. Open `Package.swift` in Xcode.
2. Select the `GodotFirebaseiOS` scheme, set destination to **Any iOS Device (arm64)**.
3. Build with **Product → Build** (Release configuration).
4. Open **Product → Show Build Folder in Finder**.
5. Navigate to `Release-iphoneos/PackageFrameworks/GodotFirebaseiOS.framework`.
6. Copy it into `demo/addons/GodotFirebaseiOS/GodotFirebaseiOS.framework`, replacing the existing one.

---

## Source Structure

```
Sources/GodotFirebaseiOS/
├── GodotFirebaseiOS.swift      # SwiftGodot entry point — registers FirebaseAuthPlugin
└── FirebaseAuthPlugin.swift    # @Godot class with all auth logic
```

### Callables registered on `FirebaseAuthPlugin`

| Method | Description |
|--------|-------------|
| `initialize()` | Loads `GoogleService-Info.plist` and configures `FirebaseApp` |
| `sign_in_anonymously()` | Anonymous auth |
| `sign_in_with_google()` | Google OAuth via `GIDSignIn` |
| `link_anonymous_with_google()` | Upgrades anonymous account to Google |
| `sign_out()` | Signs out from Firebase and Google |
| `delete_current_user()` | Deletes the current Firebase user |
| `is_signed_in() → Bool` | Returns true if a user session exists |
| `get_current_user_data() → GDictionary` | Returns `uid`, `email`, `displayName`, `photoURL`, `isAnonymous`, `providerData` |

### Signals emitted by `FirebaseAuthPlugin`

| Signal | Payload | Notes |
|--------|---------|-------|
| `firebase_initialized` | — | Internal; consumed by wrapper |
| `firebase_error(message)` | `String` | Internal; consumed by wrapper |
| `auth_success(current_user_data)` | `GDictionary` | |
| `auth_failure(error_message)` | `String` | |
| `sign_out_success(success)` | `Bool` | |
| `link_with_google_success(current_user_data)` | `GDictionary` | |
| `link_with_google_failure(error_message)` | `String` | |
| `user_deleted(success)` | `Bool` | |

---

## Key Design Decisions

**`RefCounted` instead of `Node`** — SwiftGodot GDExtension classes instantiated via `ClassDB.instantiate()` work more reliably as `RefCounted` since they do not need to be added to the scene tree.

**Separate `initialize()` callable** — SwiftGodot does not support custom `init` with parameters. Firebase initialization requires `GoogleService-Info.plist`, which must be read after Godot's filesystem is available. The wrapper calls `initialize()` immediately after instantiation.

**Anonymous re-sign behavior** — If a user is already signed in anonymously, `sign_in_anonymously()` returns existing session data rather than creating a new user, matching Android plugin behavior.

---

## Known Limitations

- Google Sign-In requires a physical iOS device (arm64). The Simulator is not supported.
- Email/Password authentication is not yet implemented (Android only).
