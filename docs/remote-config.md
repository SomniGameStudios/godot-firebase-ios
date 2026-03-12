---
title: Remote Config
nav_order: 4
layout: default
---

# Remote Config

Firebase Remote Config for iOS via the `FirebaseIOS.remote_config` autoload.

## Signals

- `fetch_completed(result: Dictionary)`
  Emitted after `fetch()` or `fetch_and_activate()` completes.
  Result keys: `{status: bool, error?: String}`.

- `activate_completed(result: Dictionary)`
  Emitted after `activate()` or `fetch_and_activate()` completes.
  Result keys: `{status: bool, error?: String}`.

- `config_updated(updated_keys: Array)`
  Emitted when a real-time config update is received (requires `listen_for_updates()`). The array contains the key names that changed. Values are automatically activated before the signal is emitted.

## Methods

{: .text-green-100 }
### set_defaults(defaults: Dictionary)

Sets default values that are used before any fetch completes. Call this early (e.g., in `_ready()`).

```gdscript
FirebaseIOS.remote_config.set_defaults({
    "welcome_message": "Hello!",
    "feature_enabled": false,
    "max_items": 10
})
```

---

{: .text-green-100 }
### set_minimum_fetch_interval(seconds: int)

Configures the minimum time between fetches. Default is 43200 (12 hours). Set to `0` during development.

```gdscript
FirebaseIOS.remote_config.set_minimum_fetch_interval(0) # Dev mode
```

---

{: .text-green-100 }
### fetch()

Fetches config values from the Firebase server. Values are not active until `activate()` is called.

**Emits:** `fetch_completed`.

```gdscript
FirebaseIOS.remote_config.fetch()
```

---

{: .text-green-100 }
### activate()

Activates the most recently fetched config values, making them available via the getters.

**Emits:** `activate_completed`.

```gdscript
FirebaseIOS.remote_config.activate()
```

---

{: .text-green-100 }
### fetch_and_activate()

Convenience method that fetches and immediately activates in a single call.

**Emits:** `fetch_completed` and `activate_completed`.

```gdscript
FirebaseIOS.remote_config.fetch_and_activate()
```

---

{: .text-green-100 }
### get_string(key: String) -> String

Returns the string value for the given key. Returns `""` if the key doesn't exist.

```gdscript
var message = FirebaseIOS.remote_config.get_string("welcome_message")
```

---

{: .text-green-100 }
### get_bool(key: String) -> bool

Returns the boolean value for the given key. Returns `false` if the key doesn't exist.

```gdscript
var enabled = FirebaseIOS.remote_config.get_bool("feature_enabled")
```

---

{: .text-green-100 }
### get_int(key: String) -> int

Returns the integer value for the given key. Returns `0` if the key doesn't exist.

```gdscript
var max_items = FirebaseIOS.remote_config.get_int("max_items")
```

---

{: .text-green-100 }
### get_float(key: String) -> float

Returns the float value for the given key. Returns `0.0` if the key doesn't exist.

```gdscript
var rate = FirebaseIOS.remote_config.get_float("spawn_rate")
```

---

{: .text-green-100 }
### get_all() -> Dictionary

Returns all remote config values as a Dictionary of `{key: string_value}`.

```gdscript
var all_config = FirebaseIOS.remote_config.get_all()
for key in all_config:
    print("%s = %s" % [key, all_config[key]])
```

---

{: .text-green-100 }
### listen_for_updates()

Starts a real-time listener for config changes. When values change on the server, the new values are automatically activated and `config_updated` is emitted with the list of changed keys.

```gdscript
FirebaseIOS.remote_config.listen_for_updates()
```

---

{: .text-green-100 }
### stop_listening_for_updates()

Stops the real-time config update listener.

```gdscript
FirebaseIOS.remote_config.stop_listening_for_updates()
```

---

## Example Usage

```gdscript
func _ready() -> void:
    # Set fallback defaults
    FirebaseIOS.remote_config.set_defaults({
        "welcome_message": "Welcome!",
        "daily_reward": 100,
        "maintenance_mode": false
    })

    # Connect signals
    FirebaseIOS.remote_config.fetch_completed.connect(_on_fetch_completed)
    FirebaseIOS.remote_config.config_updated.connect(_on_config_updated)

    # Fetch latest values
    FirebaseIOS.remote_config.fetch_and_activate()

func _on_fetch_completed(result: Dictionary) -> void:
    if result.get("status"):
        var message = FirebaseIOS.remote_config.get_string("welcome_message")
        var reward = FirebaseIOS.remote_config.get_int("daily_reward")
        print("Welcome: %s, Daily reward: %d" % [message, reward])
    else:
        print("Fetch failed: %s" % result.get("error", ""))

func _on_config_updated(updated_keys: Array) -> void:
    print("Config updated! Changed keys: %s" % str(updated_keys))
    if "maintenance_mode" in updated_keys:
        var maintenance = FirebaseIOS.remote_config.get_bool("maintenance_mode")
        if maintenance:
            show_maintenance_screen()
```
