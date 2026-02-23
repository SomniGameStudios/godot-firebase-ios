# Contributing

## Prerequisites

| Tool | Version |
|------|---------|
| Xcode | 15+ |
| Swift | 5.9+ |
| macOS | 14+ |
| Godot | 4.4+ |

## Build

```bash
cd GodotFirebaseiOS
./build_and_copy.sh        # Debug
./build_and_copy.sh r      # Release
```

The compiled framework is copied automatically to `demo/addons/GodotFirebaseiOS/`.

## Run the Demo

1. Place your `GoogleService-Info.plist` in `demo/addons/GodotFirebaseiOS/`.
2. Open `demo/` in Godot 4.4+.
3. Export to a physical iOS device (required for Google Sign-In).

## Pull Requests

Keep changes focused on a single concern, follow existing Swift and GDScript conventions, and test on a physical device before submitting.
