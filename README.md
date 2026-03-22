# Statdock

**Statdock** is a **macOS menu bar** utility that shows **CPU**, **memory**, **battery**, and **network** activity, with tabs for **overview**, **top processes** (CPU and memory), and **per-process network** throughput (via the system `nettop` tool).

## Features

| Topic | What |
|-------|------|
| **Menu bar** | Live numbers next to the chart icon (configurable metrics). Click the icon to open the main panel. |
| **Settings** | Appearance, adaptive vs fixed refresh interval, **menu bar numbers** on/off, **CPU / Memory / Battery / Network** toggles (any combination), open at login. |
| **Dock** | Hidden during normal use. Statdock appears in the Dock only while the Settings window is open. |
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

**Release DMGs are certified for distribution:** they are **Developer ID–signed**, **notarized by Apple**, and **ticket-stapled**, so Gatekeeper treats them as verified software from a known developer.

**For a public download that opens without Gatekeeper friction**, ship the artifact produced by **`make dist`** (not the ad-hoc `make dmg` output). That path requires an **Apple Developer Program** membership and a one-time machine setup.

```bash
export CODESIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'
export NOTARY_PROFILE=statdock-notary   # from: xcrun notarytool store-credentials …

make dist
```

This writes **`Dist/Statdock-<version>.dmg`** and runs Apple’s notary service + `stapler`. Upload **that** file to GitHub Releases (or your host). Full steps: **[DISTRIBUTION.md](DISTRIBUTION.md)**.

**Local / dev only** (ad-hoc signed app; **not** suitable as a frictionless download):

```bash
make dmg
```

Recipients of a **non-notarized** DMG may need **Right‑click → Open** once, or clear quarantine with `xattr` (see [DISTRIBUTION.md](DISTRIBUTION.md)).

## Usage

- **Menu bar**: Click the **chart** icon to open the panel. Use the **gear** in the panel (or **⌘,**) for Settings.
- **Quit**: **⌘Q** while Statdock is focused, or from the system’s app menu when the Settings window is key.

### Runs on its own (not tied to Cursor or any IDE)

Statdock does **not** depend on **Cursor** or any IDE when you open **`Statdock.app`** from Finder or the Dock. (If you **only** run it from a terminal, that process can exit when the terminal session ends—use Finder or **`open -a Statdock`** for a normal long‑running install, and **Open at login** in Settings if you want.)

If the **Applications** copy won’t open but a **repo** copy does, that’s usually **Gatekeeper** on a downloaded install — ship **`make dist`** (see [DISTRIBUTION.md](DISTRIBUTION.md)), not Cursor.

If you do not see the chart icon, check the menu bar **overflow** (») on notched Macs, or menu bar tools (Bartender, Ice, etc.).

### Menu bar in System Settings (ghost rows)

The menu bar extra is implemented with SwiftUI **`MenuBarExtra`** so it registers with the system the same way Apple’s templates do. If **Allow in the Menu Bar** still lists **stale Statdock rows** you cannot delete, that state lives in system preferences (not your project folder); **Reset Control Centre** does not always clear it on recent macOS versions. As a last resort you can change **`CFBundleIdentifier`** in `Info.plist` for one release so macOS treats the app as a new registration (you’ll get a fresh row; old ghosts may remain until Apple fixes the database).

## Permissions

Per-process sampling and `nettop` expect the app **not** to use the App Sandbox. The shipped `Info.plist` does not add sandbox entitlements.

## License

MIT — see [LICENSE](LICENSE).
