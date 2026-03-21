import AppKit
import SwiftUI

/// Menu bar UI is SwiftUI `MenuBarExtra` in `StatdockApp`. This delegate owns Dock tile, settings window, and metrics.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var keyDownMonitor: Any?

    private var settingsWindow: NSWindow?

    private var dockTileView: DockTileNSView?
    private var dockRedrawTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let initialPolicy: NSApplication.ActivationPolicy =
            AppSettings.shared.dockTileEnabled ? .regular : .accessory
        _ = NSApp.setActivationPolicy(initialPolicy)

        if let bid = Bundle.main.bundleIdentifier {
            let mine = ProcessInfo.processInfo.processIdentifier
            let siblings = NSRunningApplication.runningApplications(withBundleIdentifier: bid)
                .filter { $0.processIdentifier != mine }
            if !siblings.isEmpty {
                siblings.first?.activate(options: [.activateAllWindows])
                NSApp.terminate(nil)
                return
            }
        }

        MetricsStore.shared.acquire()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings(_:)),
            name: .statdockOpenSettings,
            object: nil
        )

        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers == ","
            {
                self.openSettings(nil)
                return nil
            }
            return event
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyDockTileSettings),
            name: .dockTileSettingsChanged,
            object: nil
        )
        DispatchQueue.main.async { [weak self] in
            self?.applyDockTileSettings()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applyDockTileSettings() {
        let s = AppSettings.shared
        updateActivationPolicyForAuxiliaryWindows()

        if s.dockTileEnabled {
            DispatchQueue.main.async { [weak self] in
                self?.rebuildDockTileContent()
                self?.startDockRedrawTimer()
            }
        } else {
            stopDockRedrawTimer()
            clearDockTileContent()
        }
    }

    private func rebuildDockTileContent() {
        let v = DockTileNSView(frame: NSRect(x: 0, y: 0, width: 128, height: 128))
        v.setMetrics(MetricsStore.shared, visible: AppSettings.shared.metricVisibility)
        dockTileView = v
        NSApp.dockTile.contentView = v
        v.needsDisplay = true
        updateDockBadge()
        NSApp.dockTile.display()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self, AppSettings.shared.dockTileEnabled else { return }
            self.dockTileView?.needsDisplay = true
            self.updateDockBadge()
            NSApp.dockTile.display()
        }
    }

    private func updateDockBadge() {
        guard AppSettings.shared.dockTileEnabled else { return }
        let m = MetricsStore.shared
        let v = AppSettings.shared.metricVisibility
        if v.cpu {
            NSApp.dockTile.badgeLabel = "\(Int(m.cpuTotal))"
        } else if v.memory {
            NSApp.dockTile.badgeLabel = "\(Int(m.memoryPercent))"
        } else if v.battery {
            NSApp.dockTile.badgeLabel = m.batteryInfo.map { "\($0.percent)" } ?? "—"
        } else if v.network {
            NSApp.dockTile.badgeLabel = "⇅"
        } else {
            NSApp.dockTile.badgeLabel = nil
        }
    }

    private func clearDockTileContent() {
        NSApp.dockTile.contentView = nil
        NSApp.dockTile.badgeLabel = nil
        dockTileView = nil
        NSApp.dockTile.display()
    }

    private func startDockRedrawTimer() {
        stopDockRedrawTimer()
        let t = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.dockTileView?.needsDisplay = true
                self.updateDockBadge()
                NSApp.dockTile.display()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        dockRedrawTimer = t
    }

    private func stopDockRedrawTimer() {
        dockRedrawTimer?.invalidate()
        dockRedrawTimer = nil
    }

    private func updateActivationPolicyForAuxiliaryWindows() {
        let needRegular = settingsWindow?.isVisible == true || AppSettings.shared.dockTileEnabled
        let target: NSApplication.ActivationPolicy = needRegular ? .regular : .accessory
        guard NSApp.activationPolicy() != target else {
            if needRegular {
                NSApp.unhide(nil)
                NSApp.activate(ignoringOtherApps: false)
            }
            return
        }
        if !NSApp.setActivationPolicy(target) {
            DispatchQueue.main.async {
                _ = NSApp.setActivationPolicy(target)
            }
        }
        if needRegular {
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: false)
        }
    }

    @objc private func openSettings(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)

        let window = settingsWindow ?? makeSettingsWindow()
        settingsWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        updateActivationPolicyForAuxiliaryWindows()
    }

    private func makeSettingsWindow() -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "Statdock Settings"
        w.isReleasedWhenClosed = false
        w.delegate = self
        let settingsRoot = SettingsView()
            .environmentObject(AppSettings.shared)
        w.contentViewController = NSHostingController(rootView: settingsRoot)
        return w
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let win = notification.object as? NSWindow, win === settingsWindow else { return }
        updateActivationPolicyForAuxiliaryWindows()
    }
}
