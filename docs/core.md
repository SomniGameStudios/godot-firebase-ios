---
title: Core / Initialization
nav_order: 1.5
layout: default
---

# Core / Initialization

Firebase must be initialized before any service (Auth, Firestore, etc.) can be used. The `FirebaseCorePlugin` handles this automatically when the `FirebaseIOS` autoload starts.

## How It Works

When the plugin is enabled, the `FirebaseIOS` autoload runs this sequence in `_ready()`:

1. **Core** — `FirebaseCorePlugin.initialize()` loads `GoogleService-Info.plist` and calls `FirebaseApp.configure()`
2. **Auth** — `FirebaseAuthPlugin` is instantiated and its signals are connected
3. **Firestore** — `FirebaseFirestorePlugin` is instantiated, signals are connected, and Firestore is initialized

All of this happens automatically. You do not need to call `initialize()` yourself.

## Signals

These signals are available on the `FirebaseIOS` autoload directly:

- `firebase_initialized`
  Emitted when `FirebaseApp.configure()` succeeds. At this point all services are ready to use.

- `firebase_error(message: String)`
  Emitted if initialization fails (e.g., `GoogleService-Info.plist` is missing from the app bundle).

```gdscript
func _ready() -> void:
    FirebaseIOS.firebase_initialized.connect(_on_firebase_ready)
    FirebaseIOS.firebase_error.connect(_on_firebase_error)

func _on_firebase_ready() -> void:
    print("Firebase is ready!")

func _on_firebase_error(message: String) -> void:
    printerr("Firebase init failed: ", message)
```

## GoogleService-Info.plist

The `GoogleService-Info.plist` file from your Firebase console must be included in the iOS app bundle. The plugin's export script handles this automatically — just place the file in `addons/GodotFirebaseiOS/`.

If the file is missing at runtime, `firebase_error` will be emitted with an explanatory message.

## Architecture

```
FirebaseIOS (Autoload)
├── core   → FirebaseCorePlugin    (FirebaseApp.configure)
├── auth   → FirebaseAuthPlugin    (Authentication)
└── firestore → FirebaseFirestorePlugin (Cloud Firestore)
```

Each service plugin is independent — Auth and Firestore are peers, neither depends on the other. They only require that Core has initialized Firebase first, which the autoload guarantees.
