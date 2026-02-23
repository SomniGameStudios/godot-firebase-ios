---
title: Authentication
nav_order: 2
layout: default
---

# Authentication

Firebase Authentication for iOS via the `FirebaseIOS.auth` autoload.

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

## Known Limitations

- Google Sign-In requires a physical iOS device (arm64). The iOS Simulator is not supported.
- Email/Password authentication is not yet implemented on iOS.
