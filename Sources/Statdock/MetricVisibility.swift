import Foundation

/// Which metrics appear in the menu bar and Dock tile (any combination).
struct MetricVisibility: Equatable {
    var cpu: Bool
    var memory: Bool
    var battery: Bool
    var network: Bool

    var anyEnabled: Bool { cpu || memory || battery || network }
}

extension Notification.Name {
    static let dockTileSettingsChanged = Notification.Name("StatdockDockTileSettingsChanged")
}
