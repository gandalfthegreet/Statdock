import SwiftUI

struct BatteryPanel: View {
    @EnvironmentObject private var metrics: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            if let b = metrics.batteryInfo {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Battery", systemImage: "battery.100")
                        .font(Theme.Typography.title)
                        .foregroundStyle(.secondary)
                    Text("\(b.percent)%")
                        .font(Theme.Typography.metric)
                        .foregroundStyle(Theme.ColorPalette.battery)
                    Text(b.isPluggedIn ? "AC power" : (b.isCharging ? "Charging" : "On battery"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .statdockSectionCard()

                VStack(alignment: .leading, spacing: 4) {
                    statRow("Current charge", b.currentChargeDescription ?? "\(b.percent)%")
                    statRow("Max capacity", b.maxCapacityDescription ?? "—")
                    statRow("Battery health", b.healthPercent.map { "\($0)%" } ?? "—")
                    statRow("Cycle count", b.cycleCount.map { "\($0)" } ?? "—")
                }
                .padding(12)
                .statdockSectionCard()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Estimated Impact (from CPU)", systemImage: "bolt.fill")
                        .font(Theme.Typography.title)
                        .foregroundStyle(.secondary)
                    Text("Not true energy metrics — high CPU often correlates with drain.")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(metrics.topCPU) { row in
                        HStack {
                            Text(row.name)
                                .font(Theme.Typography.row)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.1f%% CPU", row.cpuPercent))
                                .font(Theme.Typography.row)
                                .foregroundStyle(Theme.ColorPalette.accent)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(12)
                .statdockSectionCard()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Label("No battery", systemImage: "battery.0")
                        .font(Theme.Typography.title)
                        .foregroundStyle(.secondary)
                    Text("This Mac may be desktop or power info is unavailable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .statdockSectionCard()
            }
        }
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Typography.row)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(Theme.Typography.row)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}
