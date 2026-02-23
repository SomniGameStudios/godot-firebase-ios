# Cross-Platform Firebase Wrapper

If your Godot project targets both iOS and Android, you can create a unified
autoload that delegates to whichever platform plugin is available at runtime.

This avoids duplicating logic in your game scenes — they just call
`FirebaseWrapper.auth.sign_in_anonymously()` and the wrapper routes to the
correct native plugin.

## Requirements

- [GodotFirebaseiOS](https://github.com/SomniGameStudios/godot-firebase-ios) — iOS plugin
- [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid) — Android plugin

Both plugins expose a consistent Auth API with the same signals and method names,
so the wrapper is thin.

## Example: FirebaseWrapper autoload

Add this as an autoload (`Project > Project Settings > Autoload`) in your project:

```gdscript
extends Node

## Unified Firebase wrapper that detects the platform at runtime and delegates
## to the appropriate native plugin:
##   - Android: uses the Firebase autoload (GodotFirebaseAndroid)
##   - iOS: uses the FirebaseIOS autoload (GodotFirebaseiOS)
##   - Desktop/editor: no-ops with warning

enum Platform { NONE, ANDROID, IOS }

var _platform: int = Platform.NONE

# Reference the per-platform autoloads
var auth:
	get:
		match _platform:
			Platform.IOS:
				return FirebaseIOS.auth
			Platform.ANDROID:
				return Firebase.auth
		return null

func _ready() -> void:
	if ClassDB.class_exists(&"FirebaseAuthPlugin"):
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

## Usage in your scenes

```gdscript
# Works on both platforms — signals and methods are the same
func _ready() -> void:
	FirebaseWrapper.auth.auth_success.connect(_on_auth_success)
	FirebaseWrapper.auth.auth_failure.connect(_on_auth_failure)

func _on_sign_in_pressed() -> void:
	FirebaseWrapper.auth.sign_in_anonymously()
```

## Notes

- Both `FirebaseIOS` and `Firebase` (Android) autoloads must be enabled in your project
- The wrapper delegates to whichever is available — it does not duplicate the plugin logic
- Apple Sign-In is iOS only; Email/Password auth is currently Android only
- Each platform plugin is maintained independently — check their repos for the latest API
