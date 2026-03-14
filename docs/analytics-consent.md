---
title: Analytics Consent
nav_order: 6
layout: default
---

# Analytics Consent Guide

How to handle user privacy consent for Firebase Analytics in your Godot iOS game.

> **Official Firebase docs:** [Consent mode](https://firebase.google.com/docs/analytics/configure-data-collection-consent) · [Apple privacy requirements](https://support.google.com/firebase/answer/9976903)

## Overview

Privacy regulations like **GDPR** (Europe), **DMA** (Digital Markets Act), and **US state privacy laws** (CCPA, etc.) require you to obtain user consent before collecting certain types of data. Firebase Analytics provides a consent API that controls what data is collected and sent to Google.

This plugin exposes Firebase's consent API through `set_consent()`, giving you full control over consent state.

## Consent Types

Firebase defines four consent types:

| Parameter | Controls | Default |
|:--|:--|:--|
| `ad_storage` | Storage (cookies, device identifiers) related to advertising | `granted` |
| `analytics_storage` | Storage related to analytics (e.g., visit duration, app identifiers) | `granted` |
| `ad_user_data` | Sending user data to Google for advertising purposes | `granted` |
| `ad_personalization` | Personalized advertising (remarketing) | `granted` |

All consent types default to `granted`. You should call `set_consent()` **before** logging any events if your users have not yet consented.

## When Do You Need This?

**You need consent management if:**
- Your game is available in the EU/EEA (GDPR, DMA)
- Your game is available in US states with privacy laws (California, Colorado, Connecticut, etc.)
- You show ads via AdMob or other ad networks
- You collect or share user data with third parties

**You probably don't need it if:**
- Your game is only available in regions without privacy regulations
- You've disabled analytics collection entirely

## Basic Usage

```gdscript
# At app startup, before logging any events, set consent based on user choice.
# Denied by default until the user consents:
FirebaseIOS.analytics.set_consent(false, false, false, false)

# After the user grants consent:
FirebaseIOS.analytics.set_consent(true, true, true, true)
```

## Implementation Pattern

A typical flow for handling consent in a Godot game:

```gdscript
extends Node

# Call this at game startup
func _ready() -> void:
    var consent = _load_consent()
    if consent.is_empty():
        # First launch — deny all until user decides
        FirebaseIOS.analytics.set_consent(false, false, false, false)
        _show_consent_dialog()
    else:
        # Returning user — apply saved preferences
        FirebaseIOS.analytics.set_consent(
            consent.get("ad_storage", false),
            consent.get("analytics_storage", false),
            consent.get("ad_user_data", false),
            consent.get("ad_personalization", false)
        )

func _on_consent_accepted() -> void:
    # User accepted all
    FirebaseIOS.analytics.set_consent(true, true, true, true)
    _save_consent({
        "ad_storage": true,
        "analytics_storage": true,
        "ad_user_data": true,
        "ad_personalization": true
    })

func _on_consent_declined() -> void:
    # User declined — analytics only (no ad data)
    FirebaseIOS.analytics.set_consent(false, true, false, false)
    _save_consent({
        "ad_storage": false,
        "analytics_storage": true,
        "ad_user_data": false,
        "ad_personalization": false
    })

func _on_consent_minimal() -> void:
    # User wants minimum data collection
    FirebaseIOS.analytics.set_consent(false, false, false, false)
    _save_consent({
        "ad_storage": false,
        "analytics_storage": false,
        "ad_user_data": false,
        "ad_personalization": false
    })

# --- Persistence ---

const CONSENT_PATH = "user://consent.cfg"

func _save_consent(consent: Dictionary) -> void:
    var config = ConfigFile.new()
    for key in consent:
        config.set_value("consent", key, consent[key])
    config.save(CONSENT_PATH)

func _load_consent() -> Dictionary:
    var config = ConfigFile.new()
    if config.load(CONSENT_PATH) != OK:
        return {}
    var consent := {}
    for key in config.get_section_keys("consent"):
        consent[key] = config.get_value("consent", key)
    return consent

func _show_consent_dialog() -> void:
    # Show your custom consent UI here
    pass
```

## What Happens When Consent Is Denied?

When consent is denied, Firebase Analytics adjusts its behavior:

| Consent denied | Effect |
|:--|:--|
| `analytics_storage` | No analytics cookies/identifiers stored. Events are sent without identifiers (cookieless pings). |
| `ad_storage` | No advertising cookies/identifiers stored. |
| `ad_user_data` | User data is not sent to Google for advertising. |
| `ad_personalization` | No remarketing or personalized ads. |

Firebase still sends **cookieless pings** (without user identifiers) even when consent is denied, so you retain basic measurement data like event counts.

## Using with AdMob

If you also use [Godot AdMob Plugin](https://github.com/poingstudios/godot-admob-plugin), be aware that:

- **AdMob's UMP (User Messaging Platform)** handles consent dialogs and automatically updates Google's Consent Mode for all Firebase products, including Analytics.
- If UMP is managing consent, **do not** also call `set_consent()` — let UMP handle it to avoid conflicts.
- If you are **not** using AdMob/UMP, use `set_consent()` with your own consent UI.

| Setup | Who manages consent |
|:--|:--|
| Analytics only (this plugin) | You — call `set_consent()` based on your own UI |
| Analytics + AdMob with UMP | AdMob UMP — it updates consent for all Firebase SDKs automatically |
| Analytics + AdMob without UMP | You — call `set_consent()` based on your own UI |

## Apple ATT (App Tracking Transparency)

Apple's **ATT framework** is separate from Firebase Consent Mode:

- **ATT** controls access to the **IDFA** (Identifier for Advertisers) at the OS level. It's required by Apple before any cross-app tracking.
- **Consent Mode** controls what data Firebase/Google collects and processes.

They operate independently — you may need both if you use ad tracking. ATT is typically handled by the ad SDK (e.g., AdMob plugin), not by this analytics plugin.

## Recommended Consent Configurations

```gdscript
# Full consent — user agreed to everything
FirebaseIOS.analytics.set_consent(true, true, true, true)

# Analytics only — no ad-related data sharing (common for games without ads)
FirebaseIOS.analytics.set_consent(false, true, false, false)

# No consent — minimum data collection
FirebaseIOS.analytics.set_consent(false, false, false, false)

# Ads allowed but no personalization
FirebaseIOS.analytics.set_consent(true, true, true, false)
```

## Letting Users Change Their Mind

GDPR requires that users can **withdraw consent** at any time. Add a settings option:

```gdscript
func _on_privacy_settings_pressed() -> void:
    _show_consent_dialog()  # Re-show your consent UI

func _on_consent_updated(new_consent: Dictionary) -> void:
    FirebaseIOS.analytics.set_consent(
        new_consent.get("ad_storage", false),
        new_consent.get("analytics_storage", false),
        new_consent.get("ad_user_data", false),
        new_consent.get("ad_personalization", false)
    )
    _save_consent(new_consent)
```

Consent changes take effect immediately — Firebase adjusts data collection without requiring a restart.
