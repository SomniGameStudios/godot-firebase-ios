---
title: Analytics
nav_order: 5
layout: default
---

# Analytics

Firebase Analytics for iOS via the `FirebaseIOS.analytics` autoload.

> **Official Firebase docs:** [Firebase Analytics](https://firebase.google.com/docs/analytics) · [Get started (iOS)](https://firebase.google.com/docs/analytics/ios/get-started)

Note that Analytics has no signals — all methods are fire-and-forget.

## Methods

{: .text-green-100 }
### log_event(event_name: String, parameters: Dictionary = {})

Logs an analytics event with optional parameters. Use predefined event names like `"login"`, `"purchase"`, `"level_up"` for best results in the Firebase console.

```gdscript
# Simple event
FirebaseIOS.analytics.log_event("tutorial_complete")

# Event with parameters
FirebaseIOS.analytics.log_event("purchase", {
    "item_id": "sword_01",
    "item_name": "Iron Sword",
    "value": 4.99
})

# Predefined events
FirebaseIOS.analytics.log_event("login", {"method": "google"})
FirebaseIOS.analytics.log_event("level_up", {"level": 5, "character": "warrior"})
```

---

{: .text-green-100 }
### set_user_property(value: String, name: String)

Sets a user property for analytics segmentation. User properties are attributes you define to describe segments of your user base.

```gdscript
FirebaseIOS.analytics.set_user_property("premium", "membership_tier")
```

---

{: .text-green-100 }
### set_user_id(id: String)

Sets the user ID for analytics. Pass an empty string to clear the user ID.

```gdscript
FirebaseIOS.analytics.set_user_id("player_12345")

# Clear the user ID
FirebaseIOS.analytics.set_user_id("")
```

---

{: .text-green-100 }
### set_analytics_collection_enabled(enabled: bool)

Enables or disables analytics collection. When disabled, no events are logged or sent to Firebase.

```gdscript
# Disable collection (e.g., user opted out)
FirebaseIOS.analytics.set_analytics_collection_enabled(false)

# Re-enable collection
FirebaseIOS.analytics.set_analytics_collection_enabled(true)
```

---

{: .text-green-100 }
### set_default_event_parameters(parameters: Dictionary)

Sets parameters that are sent with every subsequent event. Useful for global context like app version or player segment.

```gdscript
FirebaseIOS.analytics.set_default_event_parameters({
    "app_version": "1.2.0",
    "player_segment": "returning"
})
```

---

{: .text-green-100 }
### reset_analytics_data()

Clears all analytics data for this app instance. This resets the app instance ID and any stored user properties.

```gdscript
FirebaseIOS.analytics.reset_analytics_data()
```

---

{: .text-green-100 }
### get_app_instance_id() -> String

Returns the app instance ID. Returns an empty string if analytics has not been initialized or the ID is not yet available.

```gdscript
var instance_id = FirebaseIOS.analytics.get_app_instance_id()
if instance_id != "":
    print("App Instance ID: %s" % instance_id)
```

---

{: .text-green-100 }
### set_consent(ad_storage: bool, analytics_storage: bool, ad_user_data: bool = true, ad_personalization: bool = true)

Manages analytics consent for ad storage, analytics storage, ad user data, and ad personalization. Use this to comply with privacy regulations like GDPR and DMA.

```gdscript
# User granted full consent
FirebaseIOS.analytics.set_consent(true, true, true, true)

# User denied ad tracking but allowed analytics
FirebaseIOS.analytics.set_consent(false, true, false, false)

# Minimal — only analytics, no ad-related consent
FirebaseIOS.analytics.set_consent(false, true)
```

---

{: .text-green-100 }
### set_session_timeout(seconds: int)

Sets the session timeout duration in seconds. Default is 1800 (30 minutes). A new session begins when the app is foregrounded after exceeding this timeout.

```gdscript
# Set timeout to 10 minutes
FirebaseIOS.analytics.set_session_timeout(600)
```

---

## Debug Mode

Firebase Analytics batches events and sends them roughly every hour. To see events in **real-time** during development, enable DebugView:

1. Export your Godot project to iOS
2. Open the generated `.xcodeproj` in Xcode
3. Go to **Product → Scheme → Edit Scheme** (or `Cmd+<`)
4. Select **Run → Arguments**
5. Under **Arguments Passed On Launch**, add:
   ```
   -FIRDebugEnabled
   ```
6. Run on a physical iOS device

Then open **Firebase Console → Analytics → DebugView** to see events arriving in real-time as you interact with your app.

To disable debug mode later, remove the argument or replace it with `-FIRDebugDisabled`.

> **Note:** This launch argument is set on the **exported Xcode project**, not during the plugin build. It is a runtime flag that tells the Firebase SDK to send events immediately.

---

## Example Usage

```gdscript
func _ready() -> void:
    # Set up analytics defaults
    FirebaseIOS.analytics.set_default_event_parameters({
        "app_version": "1.0.0",
        "build": "release"
    })

    # Set user ID after authentication
    var user = FirebaseIOS.auth.get_current_user_data()
    if user.has("uid"):
        FirebaseIOS.analytics.set_user_id(user["uid"])

    # Set user properties for segmentation
    FirebaseIOS.analytics.set_user_property("free", "account_type")

    # Log game start
    FirebaseIOS.analytics.log_event("game_start")

func _on_level_completed(level: int, score: int) -> void:
    FirebaseIOS.analytics.log_event("level_complete", {
        "level_number": level,
        "score": score,
        "time_spent": elapsed_time
    })

func _on_purchase_completed(item_id: String, price: float) -> void:
    FirebaseIOS.analytics.log_event("purchase", {
        "item_id": item_id,
        "value": price,
        "currency": "USD"
    })
```
