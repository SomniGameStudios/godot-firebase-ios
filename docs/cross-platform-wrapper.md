---
title: Cross-Platform
nav_order: 4
layout: default
---

# Cross-Platform (iOS + Android)

If your Godot project targets both iOS and Android, you can create a unified autoload that delegates to whichever platform plugin is available at runtime.

This avoids duplicating logic in your game scenes — they just call `FirebaseWrapper.auth.sign_in_anonymously()` and the wrapper routes to the correct native plugin.

## Requirements

- [GodotFirebaseiOS](https://github.com/SomniGameStudios/godot-firebase-ios) — iOS plugin
- [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid) — Android plugin

Both plugins expose a consistent API with the same signals and method names for Auth and Firestore, so the wrapper is thin.

## FirebaseWrapper Autoload

Add this as an autoload (**Project → Project Settings → Autoload**) in your project:

```gdscript
extends Node

## Unified Firebase wrapper that detects the platform at runtime and delegates
## to the appropriate native plugin:
##   - iOS:     uses the FirebaseIOS autoload (GodotFirebaseiOS)
##   - Android: uses the Firebase autoload (GodotFirebaseAndroid)
##   - Editor:  no-ops with warning

enum Platform { NONE, ANDROID, IOS }

var _platform: int = Platform.NONE

var auth:
    get:
        match _platform:
            Platform.IOS:
                return FirebaseIOS.auth
            Platform.ANDROID:
                return Firebase.auth
        return null

var firestore:
    get:
        match _platform:
            Platform.IOS:
                return FirebaseIOS.firestore
            Platform.ANDROID:
                return Firebase.firestore
        return null

func _ready() -> void:
    if ClassDB.class_exists(&"FirebaseCorePlugin"):
        _platform = Platform.IOS
        print("FirebaseWrapper: using iOS plugin")
    elif Engine.has_singleton("GodotFirebaseAndroid"):
        _platform = Platform.ANDROID
        print("FirebaseWrapper: using Android plugin")
    else:
        push_warning("FirebaseWrapper: No native plugin available.")

func is_available() -> bool:
    return _platform != Platform.NONE

func get_platform_name() -> String:
    match _platform:
        Platform.ANDROID: return "Android"
        Platform.IOS: return "iOS"
        _: return "None"
```

## Usage in Scenes

```gdscript
# Works on both platforms — signals and methods are identical
func _ready() -> void:
    FirebaseWrapper.auth.auth_success.connect(_on_auth_success)
    FirebaseWrapper.auth.auth_failure.connect(_on_auth_failure)
    FirebaseWrapper.firestore.get_task_completed.connect(_on_get)

func _on_sign_in_pressed() -> void:
    FirebaseWrapper.auth.sign_in_anonymously()

func _on_get_document_pressed() -> void:
    FirebaseWrapper.firestore.get_document("users", "alice123")
```

## Notes

- Both `FirebaseIOS` and `Firebase` (Android) autoloads must be enabled in your project.
- Apple Sign-In is iOS only; Email/Password auth is currently Android only.
- Each plugin is maintained independently — check their repos for the latest API.
