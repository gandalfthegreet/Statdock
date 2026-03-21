import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    private let intervals: [(label: String, value: Double)] = [
        ("1 s", 1),
        ("2.5 s", 2.5),
        ("5 s", 5),
        ("10 s", 10),
    ]

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.inline)
                Text("Match System, or lock the popover and settings window to light or dark glass.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Adaptive refresh", isOn: $settings.adaptivePolling)
                Text("When on: about 2s while metrics are changing or under load, ramping up to 30s when readings stay stable (saves CPU). When off, use the fixed interval below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Fixed interval", selection: $settings.pollIntervalSeconds) {
                    ForEach(intervals, id: \.value) { row in
                        Text(row.label).tag(row.value)
                    }
                }
                .pickerStyle(.inline)
                .disabled(settings.adaptivePolling)
                Text("Used when adaptive refresh is off, or as a fallback floor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Menu bar") {
                Toggle("Show live numbers next to the icon", isOn: $settings.menuBarLiveInfoEnabled)
                Text("When off, only the chart icon is shown. Turn off Dock below and close Settings to run menu bar only (no Dock icon).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Dock") {
                Toggle("Show live info on Dock icon", isOn: $settings.dockTileEnabled)
                Text("Off: menu bar only (no Dock icon), unless Settings is open. On: live stats on the app icon and Statdock stays in the Dock.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Metrics to show") {
                Toggle("CPU", isOn: $settings.showMetricCPU)
                Toggle("Memory", isOn: $settings.showMetricMemory)
                Toggle("Battery", isOn: $settings.showMetricBattery)
                Toggle("Network", isOn: $settings.showMetricNetwork)
                Text(layoutLegend)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Toggle("Open at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.userChangedLaunchAtLogin($0) }
                ))
                if let msg = settings.launchAtLoginMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Text("May require a notarized copy in /Applications for the system to allow login items.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 460)
        .padding()
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    private var layoutLegend: String {
        """
        Choose any combination. These values appear in the menu bar (when enabled above) and on the Dock tile.

        CPU — total usage (%). Memory — % of system RAM in use. Battery — charge % (— if unknown). Network — ↓ download / ↑ upload (distinct from the percentage metrics).
        """
    }
}
