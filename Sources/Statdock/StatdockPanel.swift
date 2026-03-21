import Foundation

/// Tabs in the main popover and kinds of floating “widget” windows.
enum StatdockPanel: String, CaseIterable, Identifiable, Hashable {
    case overview = "Overview"
    case cpu = "CPU"
    case memory = "Memory"
    case battery = "Battery"
    case network = "Network"

    var id: String { rawValue }

    var windowTitle: String {
        "Statdock — \(rawValue)"
    }
}
