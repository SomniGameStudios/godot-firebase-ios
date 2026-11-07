# Contributing

## Prerequisites

| Tool | Version |
|------|---------|
| Xcode | 26.4.1+ |
| Swift | 6.3+ |
| macOS | 26.2+ |
| Godot | 4.4+ |

## Build

```bash
make setup   # Download Firebase SDK and generate Xcode project
make build   # Compile framework and package vendor dependencies into demo/addons/GodotFirebaseiOS/
```

The compiled framework is copied automatically to `demo/addons/GodotFirebaseiOS/`.

## Run the Demo

1. Place your `GoogleService-Info.plist` in `demo/addons/GodotFirebaseiOS/`.
2. Create the export preset Godot loads (gitignored, so your signing values stay out of git):
   ```bash
   cd demo
   cp export_presets.cfg.example export_presets.cfg
   ```
3. Open `demo/` in Godot 4.4+.
4. Export to a physical iOS device (required for Google Sign-In).

## Pull Requests

Keep changes focused on a single concern, follow existing Swift and GDScript conventions, and test on a physical device before submitting.
