---
title: Authentication
nav_order: 2
layout: default
---

# Authentication

Firebase Authentication for iOS via the `FirebaseIOS.auth` autoload.

> **Official Firebase docs:** [Firebase Authentication](https://firebase.google.com/docs/auth) · [Get started (iOS)](https://firebase.google.com/docs/auth/ios/start)

## Signals

- `auth_success(current_user_data: Dictionary)`
  Emitted when a user successfully signs in.

- `auth_failure(error_message: String)`
  Emitted when an authentication operation fails.

- `link_with_google_success(current_user_data: Dictionary)`
  Emitted when an anonymous user is successfully linked to a Google account.

- `link_with_google_failure(error_message: String)`
  Emitted when linking an anonymous user to a Google account fails.

- `link_with_apple_success(current_user_data: Dictionary)`
  Emitted when an anonymous user is successfully linked to an Apple account.

- `link_with_apple_failure(error_message: String)`
  Emitted when linking an anonymous user to an Apple account fails.

- `sign_out_success(success: bool)`
  Emitted after a sign-out operation.

- `user_deleted(success: bool)`
  Emitted after an attempt to delete the current user.

- `create_user_success(current_user_data: Dictionary)`
  Emitted when a new email/password user is successfully created.

- `create_user_failure(error_message: String)`
  Emitted when creating a user fails.

- `password_reset_success(success: bool)`
  Emitted when a password reset email is sent successfully.

- `password_reset_failure(error_message: String)`
  Emitted when sending a password reset email fails.

- `auth_state_changed(signed_in: bool, current_user_data: Dictionary)`
  Emitted when the authentication state changes (user signs in or out).

- `id_token_result(token: String)`
  Emitted with the user's ID token.

- `id_token_error(error_message: String)`
  Emitted when retrieving the ID token fails.

- `profile_updated(success: bool)`
  Emitted when a profile update succeeds.

- `profile_update_failure(error_message: String)`
  Emitted when a profile update fails.

## Methods

{: .text-green-100 }
### sign_in_anonymously()

Signs in anonymously. If a session already exists, returns data for the current user without creating a new one.

**Emits:** `auth_success` or `auth_failure`.

```gdscript
FirebaseIOS.auth.sign_in_anonymously()
```

---

{: .text-green-100 }
### sign_in_with_google()

Signs in using Google OAuth via `GIDSignIn`. Requires a physical iOS device (arm64).

**Emits:** `auth_success` or `auth_failure`.

```gdscript
FirebaseIOS.auth.sign_in_with_google()
```

---

{: .text-green-100 }
### sign_in_with_apple()

Signs in using Apple Sign-In via `ASAuthorization`.

**Emits:** `auth_success` or `auth_failure`.

```gdscript
FirebaseIOS.auth.sign_in_with_apple()
```

---

{: .text-green-100 }
### link_anonymous_with_google()

Links the currently signed-in anonymous user to a Google account. The anonymous UID and data are preserved.

**Emits:** `link_with_google_success` or `link_with_google_failure`.

```gdscript
FirebaseIOS.auth.link_anonymous_with_google()
```

---

{: .text-green-100 }
### link_with_apple()

Links the currently signed-in anonymous user to an Apple account. The anonymous UID and data are preserved.

**Emits:** `link_with_apple_success` or `link_with_apple_failure`.

```gdscript
FirebaseIOS.auth.link_with_apple()
```

---

{: .text-green-100 }
### sign_out()

Signs out from Firebase and Google.

**Emits:** `sign_out_success`. Also emits `auth_failure` on failure.

```gdscript
FirebaseIOS.auth.sign_out()
```

---

{: .text-green-100 }
### delete_current_user()

Deletes the currently signed-in Firebase user.

**Emits:** `user_deleted`. Also emits `auth_failure` on failure.

```gdscript
FirebaseIOS.auth.delete_current_user()
```

---

{: .text-green-100 }
### is_signed_in() -> bool

**Returns** `true` if a user session currently exists, otherwise `false`.

```gdscript
FirebaseIOS.auth.is_signed_in()
```

---

{: .text-green-100 }
### get_current_user_data() -> Dictionary

**Returns** a dictionary with the current user's data, or an empty dictionary if no user is signed in.

- `uid` — User ID
- `email` — Email address (empty string if not available)
- `displayName` — Display name (empty string if not set)
- `photoURL` — Profile photo URL (empty string if not set)
- `isAnonymous` — Whether the user is anonymous
- `providerData` — Array of linked providers, each with `providerId`, `uid`, `email`, `displayName`, `photoURL`
- `phoneNumber` — Phone number (empty string if not set)
- `isEmailVerified` — Whether the user's email has been verified
- `metadata` — Dictionary with `creationDate` and `lastSignInDate` as ISO 8601 strings

```gdscript
var user = FirebaseIOS.auth.get_current_user_data()
```

---

{: .text-green-100 }
### use_emulator(host: String, port: int)

Connects to the Firebase Auth Emulator. Call this before any auth operations.

```gdscript
FirebaseIOS.auth.use_emulator("localhost", 9099)
```

---

{: .text-green-100 }
### create_user_with_email(email: String, password: String)

Creates a new user with email and password.

**Emits:** `create_user_success` or `create_user_failure`.

```gdscript
FirebaseIOS.auth.create_user_with_email("user@example.com", "password123")
```

---

{: .text-green-100 }
### sign_in_with_email(email: String, password: String)

Signs in with email and password.

**Emits:** `auth_success` or `auth_failure`.

```gdscript
FirebaseIOS.auth.sign_in_with_email("user@example.com", "password123")
```

---

{: .text-green-100 }
### send_password_reset_email(email: String)

Sends a password reset email.

**Emits:** `password_reset_success` or `password_reset_failure`.

```gdscript
FirebaseIOS.auth.send_password_reset_email("user@example.com")
```

---

{: .text-green-100 }
### add_auth_state_listener()

Starts listening for auth state changes.

**Emits:** `auth_state_changed` whenever the user signs in or out.

```gdscript
FirebaseIOS.auth.add_auth_state_listener()
```

---

{: .text-green-100 }
### remove_auth_state_listener()

Stops listening for auth state changes.

```gdscript
FirebaseIOS.auth.remove_auth_state_listener()
```

---

{: .text-green-100 }
### get_id_token(force_refresh: bool = false)

Retrieves the current user's Firebase ID token.

**Emits:** `id_token_result` or `id_token_error`.

```gdscript
FirebaseIOS.auth.get_id_token(false)
```

---

{: .text-green-100 }
### update_profile(display_name: String, photo_url: String = "")

Updates the current user's display name and/or photo URL. Only non-empty values are applied.

**Emits:** `profile_updated` or `profile_update_failure`.

```gdscript
FirebaseIOS.auth.update_profile("Alice", "")
```

---

{: .text-green-100 }
### update_password(new_password: String)

Updates the current user's password. May require recent reauthentication.

**Emits:** `profile_updated` or `auth_failure`.

```gdscript
FirebaseIOS.auth.update_password("newSecurePassword")
```

---

{: .text-green-100 }
### send_email_verification()

Sends an email verification to the current user.

**Emits:** `profile_updated` or `auth_failure`.

```gdscript
FirebaseIOS.auth.send_email_verification()
```

---

{: .text-green-100 }
### reload_user()

Reloads the current user's data from the server.

**Emits:** `auth_success` with refreshed data, or `auth_failure`.

```gdscript
FirebaseIOS.auth.reload_user()
```

---

{: .text-green-100 }
### unlink_provider(provider_id: String)

Unlinks a provider from the current user.

**Emits:** `auth_success` or `auth_failure`.

```gdscript
FirebaseIOS.auth.unlink_provider("google.com")
```

---

{: .text-green-100 }
### reauthenticate_with_email(email: String, password: String)

Reauthenticates the current user with email credentials. Required before sensitive operations.

**Emits:** `auth_success` or `auth_failure`.

```gdscript
FirebaseIOS.auth.reauthenticate_with_email("user@example.com", "password123")
```

---

## Prerequisites

### Apple Sign-In

Apple Sign-In requires the **Sign in with Apple** entitlement. Without it, `sign_in_with_apple()` and `link_with_apple()` will fail with `ASAuthorizationError error 1000`.

1. **Godot Export Presets:** iOS export > Entitlements > Additional — append:
   ```
   <key>com.apple.developer.applesignin</key>
   <array><string>Default</string></array>
   ```
2. **Apple Developer Portal:** Certificates, Identifiers & Profiles > your App ID > enable "Sign in with Apple"

### Google Sign-In

Google Sign-In requires the `REVERSED_CLIENT_ID` URL scheme in your `Info.plist` (from `GoogleService-Info.plist`). See [Firebase docs](https://firebase.google.com/docs/auth/ios/google-signin).

## Known Limitations

- Google Sign-In requires a physical iOS device (arm64). The iOS Simulator is not supported.
