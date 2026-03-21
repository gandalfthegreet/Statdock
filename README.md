# Statdock

**Statdock** is a small **macOS menu bar** app that shows **CPU**, **memory**, **battery**, and **network** activity, including **top processes** by CPU and memory and **per-process network throughput** (via the system `nettop` tool).

Unrelated to [Kubernetes Helm](https://helm.sh) or other unrelated products with similar names.

## Highlights

| Topic | What Statdock does |
|--------|-------------------|
| **Adaptive refresh** | Default **~2 s** when load or readings change, ramping toward **30 s** when stable (toggle in Settings; reduces timer wakeups). |
| **Direct system access** | **IOKit** (battery), **host processors** / **libproc** (CPU & processes, resident memory). |
| **Demand-driven polling** | Sampling runs while the **popover** is open, or in the **background** when **Dock icon live info** is enabled in Settings (`acquire` / `release`). |
| **Dynamic Dock icon** | Optional **live CPU / memory / battery / network** overlay on the app icon (`NSDockTile`). The app bundle is **not** `LSUIElement`-only so the icon can appear in the Dock when this is enabled (`NSApp` uses `.accessory` by default, `.regular` when the tile or Settings is active). |
| **Universal binary** | Build for both architectures (see [Build](#build)). |
| **Memory** | Small in-process state; process lists are bounded (top *N*). |
| **Per-process network** | Uses **`/usr/bin/nettop`** (subprocess) — not pure in-process I/O. |

### Roadmap (not implemented yet)

- **Smart notch integration** and **notch glow alerts** (animated emphasis for battery/device events on notched MacBooks) would require custom window / layout work around the camera housing and are **not in this repo yet**. If you add them, plan for private window placement, animation, and accessibility.

## Requirements

- macOS 13+
- Xcode / Swift 6 toolchain (for building)

## Build

```bash
cd Statdock
swift build
```

### Universal binary (Intel + Apple Silicon)

On a Mac with the Swift toolchain:

```bash
swift build -c release --arch arm64 --arch x86_64
```

Then copy the binary into your `.app` as in `make app` (see below).

## Run from a dev bundle

The SwiftPM binary does not show a menu bar icon when run raw; build an `.app` bundle:

```bash
cd /path/to/Statdock
make app
```

The app is placed next to the project as **`Dist/Statdock.app`** (not in `/tmp`, so it shows up in Finder and file browsers when you open the Statdock folder).

```bash
open "Dist/Statdock.app"
```

Or in **Finder**: open the `Statdock` project folder → **`Dist`** → double‑click **`Statdock.app`**.

### DMG for downloads (GitHub Releases, etc.)

Build a **compressed** `.dmg` next to the app (includes a shortcut to **Applications** for drag‑to‑install):

```bash
make dmg
```

Output: **`Dist/Statdock-<version>.dmg`** (version comes from `Info.plist` → `CFBundleShortVersionString`). Upload that file for others to download. Recipients open the DMG, drag **Statdock** into **Applications**, then eject the disk image.

Codesigning / notarization for wide distribution is separate from creating the DMG; unsigned builds may require **Control‑click → Open** the first time.

**Controls:** **Left‑click** the chart icon for the panel. **Right‑click** for **Settings…** and **Quit**. **⌘,** opens Settings; **⌘Q** quits. In Settings, enable **Show live info on Dock icon** for a dynamic Dock tile.

### If nothing appears in the menu bar

Statdock uses a normal **`NSStatusItem`** (chart icon). After launch you should see that icon on the **right** side of the menu bar.

1. **Rebuild** after changes: `make app` again, then open **`Dist/Statdock.app`** (not the raw `swift` binary).
2. **Click the chart icon** — a popover opens (the app does not use Dock; there is no main window).
3. **Gatekeeper**: unsigned builds may need **Control‑click → Open** on `Statdock.app` the first time.
4. **Quit stuck copies** (or after testing many launches): in Terminal run **`killall Statdock`**, or use **Activity Monitor** → search **`Statdock`** → **Quit** each row.
5. Run from Terminal to confirm the process stays up:  
   `"/Volumes/Crucial X9/GitHub/My-Repos/Statdock/Dist/Statdock.app/Contents/MacOS/Statdock"`  
   (Use your own path if different.) Leave it running and check the menu bar.

## Permissions / sandbox

For full **per-process** CPU/memory sampling (`libproc`) and **`nettop`**, distribute **without** App Sandbox (GitHub / Developer ID). This template does not add sandbox entitlements to the dev `Info.plist`.

## License

SPDX: MIT — see [LICENSE](LICENSE) (add your name/year).
