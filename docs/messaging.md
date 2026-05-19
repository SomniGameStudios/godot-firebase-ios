---
layout: default
title: Cloud Messaging (FCM)
nav_order: 3
---

# Firebase Cloud Messaging

Push notifications via Firebase Cloud Messaging (FCM) on iOS.

## Setup

### 1. Enable Push Notifications Capability

In Xcode, go to **Signing & Capabilities** → **+ Capability** → **Push Notifications**.

### 2. Generate APNs Key

In [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list):
1. Create an APNs Authentication Key (`.p8` file)
2. Upload it to **Firebase Console** → **Project Settings** → **Cloud Messaging** → **APNs Authentication Key**

### 3. Export Plugin (Automatic)

The export plugin automatically injects:
- `FirebaseAppDelegateProxyEnabled = false` (disables Firebase swizzling)
- `UIBackgroundModes: remote-notification` (enables background push delivery)

No manual Info.plist changes needed.

---

## Usage

### Initialize

```gdscript
func _ready() -> void:
    FirebaseIOS.messaging.token_received.connect(_on_token)
    FirebaseIOS.messaging.notification_received.connect(_on_notification)
    FirebaseIOS.messaging.notification_opened.connect(_on_notification_opened)
    FirebaseIOS.messaging.permission_result.connect(_on_permission)
    
    FirebaseIOS.messaging.configure()
```

> **Important:** Call `configure()` after Firebase has been initialized (after `FirebaseIOS.auth.initialize()`). The export plugin handles this automatically, but if you're managing initialization manually, ensure Firebase is configured first.

### Request Permission

```gdscript
FirebaseIOS.messaging.request_permission()

# Or with provisional delivery (silent notifications, no dialog):
FirebaseIOS.messaging.request_permission(true)
```

### Check Permission Status

```gdscript
var status := FirebaseIOS.messaging.get_permission_status()
# Returns: "not_determined", "authorized", "denied", "provisional", "ephemeral"
```

### Get FCM Token

```gdscript
FirebaseIOS.messaging.get_token()

func _on_token(token: String) -> void:
    print("FCM Token: ", token)
```

### Delete Token (Logout)

```gdscript
FirebaseIOS.messaging.delete_token()
```

### Topics

```gdscript
FirebaseIOS.messaging.subscribe_to_topic("all_users")
FirebaseIOS.messaging.unsubscribe_from_topic("all_users")
```

---

## Signals

| Signal | Arguments | Description |
|--------|-----------|-------------|
| `token_received` | `token: String` | FCM registration token (initial + refresh) |
| `notification_received` | `data: Dictionary` | Foreground notification payload |
| `notification_opened` | `data: Dictionary` | User tapped a notification |
| `permission_result` | `granted: bool` | Result of `request_permission()` |
| `topic_subscribe_success` | `topic: String` | Topic subscription succeeded |
| `topic_subscribe_failure` | `message: String` | Topic subscription failed |
| `topic_unsubscribe_success` | `topic: String` | Topic unsubscription succeeded |
| `topic_unsubscribe_failure` | `message: String` | Topic unsubscription failed |
| `token_delete_success` | — | Token deleted |
| `token_delete_failure` | `message: String` | Token deletion failed |

## Notification Payload

The `data` Dictionary from `notification_received` and `notification_opened` contains:

| Key | Description |
|-----|-------------|
| `_title` | Notification title (from `aps.alert.title`) |
| `_body` | Notification body (from `aps.alert.body`) |
| `_badge` | Badge count (from `aps.badge`) |
| `_sound` | Sound name (from `aps.sound`) |
| Custom keys | Your custom data keys from the `data` payload |

> Keys prefixed with `google.` and `gcm.` are filtered out.

## Recommended Flow

```
1. Initialize Firebase (auth.initialize())
2. Configure messaging (messaging.configure())
3. Wait for appropriate trigger (first sync, first reward)
4. Show in-app priming screen
5. On "Enable" → messaging.request_permission()
6. On permission_result(true) → messaging.get_token()
7. Store token server-side
```

## Platform Notes

- **iOS permission is one-shot.** If denied, the app can never re-prompt. Direct users to Settings.
- **Firebase swizzling is disabled.** The plugin handles APNs token mapping manually.
- **Data-only messages to killed apps are not delivered on iOS.** Use notification-type or combined messages for critical alerts.
- **Silent push budget:** ~2-3 per hour before iOS throttles.
