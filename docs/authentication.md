---
title: Authentication
nav_order: 2
layout: default
---

# Authentication
{: .no_toc }

Firebase Authentication for iOS via the `FirebaseIOS.auth` autoload.
{: .fs-6 .fw-300 }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Setup

Connect signals before calling any auth methods:

```gdscript
func _ready() -> void:
    FirebaseIOS.auth.auth_success.connect(_on_auth_success)
    FirebaseIOS.auth.auth_failure.connect(_on_auth_failure)
```

---

## Methods

### `sign_in_anonymously()`

Signs in anonymously. If a session already exists, returns data for the current user without creating a new one.

**Emits:** `auth_success` or `auth_failure`

---

### `sign_in_with_google()`

Initiates Google OAuth sign-in via `GIDSignIn`. Requires a physical iOS device (arm64).

**Emits:** `auth_success` or `auth_failure`

---

### `sign_in_with_apple()`

Initiates Apple Sign-In via `ASAuthorization`.

**Emits:** `auth_success` or `auth_failure`

---

### `link_anonymous_with_google()`

Links an existing anonymous account to a Google credential.

**Emits:** `link_with_google_success` or `link_with_google_failure`

---

### `link_with_apple()`

Links an existing anonymous account to an Apple credential.

**Emits:** `link_with_apple_success` or `link_with_apple_failure`

---

### `sign_out()`

Signs out from Firebase and Google.

**Emits:** `sign_out_success`

---

### `delete_current_user()`

Deletes the current Firebase user.

**Emits:** `user_deleted` or `auth_failure`

---

### `is_signed_in() → bool`

Returns `true` if a user session currently exists.

---

### `get_current_user_data() → Dictionary`

Returns the current user's data, or an empty `Dictionary` if no user is signed in. See [User Data](#user-data).

---

### `use_emulator(host: String, port: int)`

Connects to the Firebase Auth Emulator. Must be called after the plugin initializes.

---

## Signals

| Signal | Payload | Description |
|--------|---------|-------------|
| `auth_success(current_user_data)` | `Dictionary` | Emitted on successful sign-in |
| `auth_failure(error_message)` | `String` | Emitted on sign-in failure |
| `sign_out_success(success)` | `bool` | Emitted after sign-out |
| `user_deleted(success)` | `bool` | Emitted after user deletion |
| `link_with_google_success(current_user_data)` | `Dictionary` | Emitted on successful Google link |
| `link_with_google_failure(error_message)` | `String` | Emitted on Google link failure |
| `link_with_apple_success(current_user_data)` | `Dictionary` | Emitted on successful Apple link |
| `link_with_apple_failure(error_message)` | `String` | Emitted on Apple link failure |

---

## User Data

`auth_success`, `link_with_google_success`, and `link_with_apple_success` all emit a `Dictionary` with the following structure:

```gdscript
{
    "uid":          "abc123",
    "email":        "user@example.com",  # empty string if not available
    "displayName":  "John Doe",          # empty string if not set
    "photoURL":     "https://...",       # empty string if not set
    "isAnonymous":  false,
    "providerData": [                    # mirrors Firebase User.providerData
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

`get_current_user_data()` returns the same structure, or an empty `Dictionary` if no user is signed in.

---

## Example

```gdscript
extends Control

func _ready() -> void:
    FirebaseIOS.auth.auth_success.connect(_on_auth_success)
    FirebaseIOS.auth.auth_failure.connect(_on_auth_failure)
    FirebaseIOS.auth.sign_out_success.connect(_on_sign_out_success)

func _on_sign_in_anonymously_pressed() -> void:
    FirebaseIOS.auth.sign_in_anonymously()

func _on_sign_in_with_google_pressed() -> void:
    FirebaseIOS.auth.sign_in_with_google()

func _on_sign_in_with_apple_pressed() -> void:
    FirebaseIOS.auth.sign_in_with_apple()

func _on_sign_out_pressed() -> void:
    FirebaseIOS.auth.sign_out()

func _on_auth_success(user_data: Dictionary) -> void:
    print("Signed in: ", user_data.uid)
    print("Anonymous: ", user_data.isAnonymous)
    print("Providers: ", user_data.providerData)

func _on_auth_failure(error_message: String) -> void:
    print("Auth error: ", error_message)

func _on_sign_out_success(success: bool) -> void:
    print("Signed out: ", success)
```

---

## Known Limitations

- Google Sign-In requires a physical iOS device (arm64). The iOS Simulator is not supported.
- Email/Password authentication is not yet implemented on iOS.
