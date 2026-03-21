# Statdock

**Statdock** is a **macOS menu bar** utility that shows **CPU**, **memory**, **battery**, and **network** activity, with tabs for **overview**, **top processes** (CPU and memory), and **per-process network** throughput (via the system `nettop` tool).

## Features

| Topic | What |
|-------|------|
| **Menu bar** | Live numbers next to the chart icon (configurable metrics). Click the icon to open the main panel. |
| **Settings** | Appearance, adaptive vs fixed refresh interval, **menu bar numbers** on/off, **Dock live tile** on/off, **CPU / Memory / Battery / Network** toggles (any combination), open at login. |
| **Dock** | Optional live overlay and badge on the app icon when enabled; turn off for **menu bar only** (no Dock icon when Settings is closed). |
| **Data** | IOKit (battery), host CPU and **libproc** (CPU, processes, resident memory), interface throughput, **`/usr/bin/nettop`** for per-process network. |
| **Adaptive polling** | ~2 s while load or values are changing, up to ~30 s when stable (Settings). |

## Requirements

- **macOS 14** or later (see `LSMinimumSystemVersion` in `Info.plist`)
- **Swift 6** toolchain to build from source

## Build

```bash
cd Statdock   # repository root
swift build -c release
```

**App bundle** (required to run the menu bar UI; output under `Dist/`):

```bash
make app
open "Dist/Statdock.app"
```

**Universal binary** (Intel + Apple Silicon), then install into the `.app` the same way `make app` does:

```bash
swift build -c release --arch arm64 --arch x86_64
```

## Distribution (DMG)

```bash
make dmg
```

Produces **`Dist/Statdock-<version>.dmg`** (version from `CFBundleShortVersionString` in `Info.plist`), with **`Statdock.app`** and a shortcut to **Applications** for drag-to-install. Upload for GitHub Releases or similar.

First launch on other Macs may require **Control-click → Open** if the app is not signed and notarized.

## Usage

- **Menu bar**: Click the **chart** icon to open the panel. Use the **gear** in the panel (or **⌘,**) for Settings.
- **Quit**: **⌘Q** while Statdock is focused, or from the system’s app menu when the Settings window is key.

## Permissions

Per-process sampling and `nettop` expect the app **not** to use the App Sandbox. The shipped `Info.plist` does not add sandbox entitlements.

## License

MIT — see [LICENSE](LICENSE).
