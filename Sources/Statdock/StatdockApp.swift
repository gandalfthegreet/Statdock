import AppKit
import SwiftUI

extension Notification.Name {
    /// Opens the AppKit settings window (`AppDelegate.openSettings`).
    static let statdockOpenSettings = Notification.Name("statdock.openSettings")
}

@main
struct StatdockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MainPopoverView()
                .environmentObject(MetricsStore.shared)
                .environmentObject(AppSettings.shared)
        } label: {
            MenuBarExtraLabelView()
                .environmentObject(MetricsStore.shared)
                .environmentObject(AppSettings.shared)
        }
        .menuBarExtraStyle(.window)

        Settings {
            EmptyView()
        }
    }
}
