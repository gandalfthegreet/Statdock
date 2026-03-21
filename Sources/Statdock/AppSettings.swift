import Foundation
import ServiceManagement
import SwiftUI

/// User defaults + launch-at-login (`SMAppService`).
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var pollIntervalSeconds: Double {
        didSet { UserDefaults.standard.set(pollIntervalSeconds, forKey: Keys.pollInterval) }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Keys.appearance)
            AppAppearance.apply(appearanceMode)
        }
    }

    @Published var adaptivePolling: Bool {
        didSet { UserDefaults.standard.set(adaptivePolling, forKey: Keys.adaptivePolling) }
    }

    @Published var launchAtLogin: Bool

    @Published var launchAtLoginMessage: String?

    @Published var dockTileEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dockTileEnabled, forKey: Keys.dockTileEnabled)
            postDockNotification()
        }
    }

    @Published var menuBarLiveInfoEnabled: Bool {
        didSet {
            UserDefaults.standard.set(menuBarLiveInfoEnabled, forKey: Keys.menuBarLiveInfo)
        }
    }

    @Published var showMetricCPU: Bool {
        didSet {
            UserDefaults.standard.set(showMetricCPU, forKey: Keys.showCPU)
            postDockNotification()
        }
    }

    @Published var showMetricMemory: Bool {
        didSet {
            UserDefaults.standard.set(showMetricMemory, forKey: Keys.showMemory)
            postDockNotification()
        }
    }

    @Published var showMetricBattery: Bool {
        didSet {
            UserDefaults.standard.set(showMetricBattery, forKey: Keys.showBattery)
            postDockNotification()
        }
    }

    @Published var showMetricNetwork: Bool {
        didSet {
            UserDefaults.standard.set(showMetricNetwork, forKey: Keys.showNetwork)
            postDockNotification()
        }
    }

    var metricVisibility: MetricVisibility {
        MetricVisibility(
            cpu: showMetricCPU,
            memory: showMetricMemory,
            battery: showMetricBattery,
            network: showMetricNetwork
        )
    }

    private enum Keys {
        static let pollInterval = "statdock.pollIntervalSeconds"
        static let appearance = "statdock.appearanceMode"
        static let adaptivePolling = "statdock.adaptivePolling"
        static let launchAtLogin = "statdock.launchAtLogin"
        static let dockTileEnabled = "statdock.dockTileEnabled"
        static let menuBarLiveInfo = "statdock.menuBarLiveInfo"
        static let showCPU = "statdock.showMetric.cpu"
        static let showMemory = "statdock.showMetric.memory"
        static let showBattery = "statdock.showMetric.battery"
        static let showNetwork = "statdock.showMetric.network"
        static let dockTileLayoutLegacy = "statdock.dockTileLayout"
    }

    private init() {
        let d = UserDefaults.standard
        if let v = d.object(forKey: Keys.pollInterval) as? Double, v >= 0.5 {
            pollIntervalSeconds = v
        } else {
            pollIntervalSeconds = 2.5
        }
        if let raw = d.string(forKey: Keys.appearance), let m = AppearanceMode(rawValue: raw) {
            appearanceMode = m
        } else {
            appearanceMode = .system
        }
        if d.object(forKey: Keys.adaptivePolling) != nil {
            adaptivePolling = d.bool(forKey: Keys.adaptivePolling)
        } else {
            adaptivePolling = true
        }

        launchAtLogin = d.bool(forKey: Keys.launchAtLogin)
        launchAtLoginMessage = nil

        if d.object(forKey: Keys.dockTileEnabled) != nil {
            dockTileEnabled = d.bool(forKey: Keys.dockTileEnabled)
        } else {
            dockTileEnabled = false
        }
        if d.object(forKey: Keys.menuBarLiveInfo) != nil {
            menuBarLiveInfoEnabled = d.bool(forKey: Keys.menuBarLiveInfo)
        } else {
            menuBarLiveInfoEnabled = true
        }

        let flags = Self.loadMetricFlags(from: d)
        showMetricCPU = flags.cpu
        showMetricMemory = flags.mem
        showMetricBattery = flags.bat
        showMetricNetwork = flags.net

        syncLaunchStatusFromService()
        AppAppearance.apply(appearanceMode)
    }

    private static func loadMetricFlags(from d: UserDefaults) -> (cpu: Bool, mem: Bool, bat: Bool, net: Bool) {
        if d.object(forKey: Keys.showCPU) != nil {
            return (
                d.bool(forKey: Keys.showCPU),
                d.bool(forKey: Keys.showMemory),
                d.bool(forKey: Keys.showBattery),
                d.bool(forKey: Keys.showNetwork)
            )
        }
        if let raw = d.string(forKey: Keys.dockTileLayoutLegacy) {
            let r: (Bool, Bool, Bool, Bool)
            switch raw {
            case "summary": r = (true, true, true, true)
            case "cpu": r = (true, false, false, false)
            case "memory": r = (false, true, false, false)
            case "battery": r = (false, false, true, false)
            case "network": r = (false, false, false, true)
            default: r = (true, true, true, true)
            }
            d.set(r.0, forKey: Keys.showCPU)
            d.set(r.1, forKey: Keys.showMemory)
            d.set(r.2, forKey: Keys.showBattery)
            d.set(r.3, forKey: Keys.showNetwork)
            d.removeObject(forKey: Keys.dockTileLayoutLegacy)
            return (r.0, r.1, r.2, r.3)
        }
        return (true, true, true, true)
    }

    private func postDockNotification() {
        NotificationCenter.default.post(name: .dockTileSettingsChanged, object: nil)
    }

    func syncLaunchStatusFromService() {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
        UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
    }

    func userChangedLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.launchAtLogin)
        launchAtLoginMessage = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            syncLaunchStatusFromService()
        } catch {
            launchAtLoginMessage = error.localizedDescription
            syncLaunchStatusFromService()
        }
    }
}
