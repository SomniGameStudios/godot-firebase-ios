# Privacy manifest (consumer responsibility)

GodotFirebaseiOS does **not** ship a `PrivacyInfo.xcprivacy`. Privacy declaration belongs
to the **consuming app**, which owns its App Store privacy "nutrition label".

This matters because GodotFirebaseiOS statically links Firebase (compiled from source via
SwiftPM). Static linking strips Firebase's per-module `PrivacyInfo.xcprivacy` bundles, and
the **required-reason API** calls Firebase makes become part of *your app's* binary. So
*your app* must declare them, or App Store validation rejects the upload (ITMS-91056 —
missing required-reason API declaration).

## In Godot: declare via the iOS export preset

Godot generates the app's `PrivacyInfo.xcprivacy` from the **iOS export preset** privacy
fields (Project → Export → iOS → Privacy). Set these so they cover Firebase:

| Export preset field | Tick (Godot reason) | Why |
|---|---|---|
| User Defaults Access Reasons | `CA92.1` + `1C8F.1` | Firebase reads/writes `UserDefaults` (app + app-group). `C56D.1` is the SDK-*vendor* reason and does not apply once Firebase is statically linked into your app — Godot doesn't offer it, which is correct. |
| File Timestamp Access Reasons | `C617.1` | Firebase reads file timestamps |
| System Boot Time Access Reasons | `35F9.1` | Firebase reads system uptime |

Then declare the data your app actually collects via Firebase under the preset's
`privacy/collected_data/*` fields and `privacy/tracking_*`. For the modules this plugin
exposes (Auth, Firestore, Database, RemoteConfig, Analytics, Messaging, GoogleSignIn) the
typical set is: DeviceID, UserID, EmailAddress, Name, PhoneNumber, CoarseLocation, plus
usage/diagnostic/crash data — **trim to what your app truly collects** (this is your App
Store privacy-label decision, not the plugin's).

## Raw Apple manifest (non-Godot / manual reference)

If you assemble a `PrivacyInfo.xcprivacy` by hand, the required-reason APIs are:

```
NSPrivacyAccessedAPICategoryUserDefaults   → CA92.1, 1C8F.1, C56D.1
NSPrivacyAccessedAPICategoryFileTimestamp  → C617.1
NSPrivacyAccessedAPICategorySystemBootTime → 35F9.1
```

Re-check against [Firebase's published privacy details](https://firebase.google.com/docs/ios/app-store-data-collection)
whenever you bump the Firebase version.
