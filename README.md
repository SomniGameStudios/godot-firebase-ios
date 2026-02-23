# godot-firebase-ios

Firebase Authentication plugin for Godot 4 on iOS, built with [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) GDExtension.

Mirrors the API of [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid) for a consistent cross-platform experience.

---

## Features

- Anonymous Sign-In
- Google Sign-In
- Apple Sign-In
- Account linking (Google, Apple)
- Delete user
- Auth emulator support

---

## Installation

### From Release (recommended)

1. Download the latest release zip from [Releases](https://github.com/SomniGameStudios/godot-firebase-ios/releases).
2. Extract `addons/GodotFirebaseiOS/` into your Godot project's `addons/` folder.
3. Enable the plugin in **Project > Project Settings > Plugins**. The `FirebaseIOS` autoload is registered automatically.
4. Place your `GoogleService-Info.plist` in `addons/GodotFirebaseiOS/`.

### Build from Source

See [GodotFirebaseiOS/README.md](GodotFirebaseiOS/README.md) for build instructions, or use the build script:

```bash
cd GodotFirebaseiOS
./build_and_copy.sh        # Debug build
./build_and_copy.sh r      # Release build
```

---

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 15+ |
| Swift | 5.9+ |
| iOS deployment target | 17+ |
| macOS (build machine) | 14+ |
| Godot | 4.4+ |

---

## Usage

All methods are accessed through the `FirebaseIOS.auth` autoload:

```gdscript
func _ready() -> void:
    FirebaseIOS.auth.auth_success.connect(_on_auth_success)
    FirebaseIOS.auth.auth_failure.connect(_on_auth_failure)

func _on_sign_in_pressed() -> void:
    FirebaseIOS.auth.sign_in_anonymously()

func _on_auth_success(user_data: Dictionary) -> void:
    print("Signed in: ", user_data.uid)

func _on_auth_failure(error_message: String) -> void:
    print("Error: ", error_message)
```

### Auth Methods

| Method | Description |
|--------|-------------|
| `sign_in_anonymously()` | Anonymous auth (returns existing session if already signed in) |
| `sign_in_with_google()` | Google OAuth via GIDSignIn |
| `sign_in_with_apple()` | Apple Sign-In via ASAuthorization |
| `link_anonymous_with_google()` | Link anonymous account to Google |
| `link_with_apple()` | Link anonymous account to Apple |
| `sign_out()` | Sign out from Firebase and Google |
| `delete_current_user()` | Delete the current Firebase user |
| `is_signed_in() → bool` | Returns true if a user session exists |
| `get_current_user_data() → Dictionary` | Returns uid, email, displayName, photoURL, isAnonymous |
| `use_emulator(host, port)` | Connect to Firebase Auth Emulator |

### Signals

| Signal | Payload |
|--------|---------|
| `auth_success(current_user_data)` | `Dictionary` |
| `auth_failure(error_message)` | `String` |
| `sign_out_success(success)` | `bool` |
| `user_deleted(success)` | `bool` |
| `link_with_google_success(current_user_data)` | `Dictionary` |
| `link_with_google_failure(error_message)` | `String` |
| `link_with_apple_success(current_user_data)` | `Dictionary` |
| `link_with_apple_failure(error_message)` | `String` |

### User Data Dictionary

```gdscript
{
    "uid": "abc123",
    "email": "user@example.com",
    "displayName": "John Doe",
    "photoURL": "https://...",
    "isAnonymous": false,
    "providerData": [           # mirrors Firebase User.providerData
        {
            "providerId":  "google.com",
            "uid":         "1234567890",
            "email":       "user@example.com",
            "displayName": "John Doe",
            "photoURL":    "https://..."
        }
    ]
}
```

---

## Cross-Platform (iOS + Android)

This plugin can coexist with [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid).
Both expose the same Auth API (`sign_in_anonymously()`, `auth_success`, etc.), so you can
write a thin wrapper that delegates to the correct platform at runtime.

See [docs/cross-platform-wrapper.md](docs/cross-platform-wrapper.md) for an example.

---

## Project Structure

```
godot-firebase-ios/
├── GodotFirebaseiOS/          # Swift SPM package (plugin source)
│   ├── Package.swift
│   ├── Sources/
│   └── build_and_copy.sh
├── demo/                      # Godot demo project
│   ├── addons/GodotFirebaseiOS/
│   └── scenes/
├── docs/                      # Documentation
└── README.md
```

---

## Known Limitations

- Google Sign-In requires a physical iOS device (arm64). Simulator is not supported.
- Email/Password authentication is not yet implemented on iOS.

---

## License

MIT — see [LICENSE](LICENSE).
