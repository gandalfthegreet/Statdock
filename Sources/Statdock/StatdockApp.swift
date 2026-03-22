import SwiftUI

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
    }
}
