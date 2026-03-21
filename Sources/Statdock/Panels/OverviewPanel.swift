import SwiftUI

struct OverviewPanel: View {
    @EnvironmentObject private var metrics: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            metricCard(title: "CPU", value: "\(Int(metrics.cpuTotal))%", color: Theme.ColorPalette.cpu)
            metricCard(title: "Memory", value: "\(Int(metrics.memoryPercent))%", color: Theme.ColorPalette.memory)
            networkCard
            metricCard(
                title: "Battery",
                value: metrics.batteryInfo.map { "\($0.percent)%" } ?? "—",
                color: Theme.ColorPalette.battery
            )
        }
    }

    private var networkCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NETWORK")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Label(Theme.throughputString(metrics.networkDownBps), systemImage: "arrow.down.circle")
                    .font(Theme.Typography.row)
                    .foregroundColor(Theme.ColorPalette.network)
                Label(Theme.throughputString(metrics.networkUpBps), systemImage: "arrow.up.circle")
                    .font(Theme.Typography.row)
                    .foregroundColor(Theme.ColorPalette.accent)
            }
            .labelStyle(.titleAndIcon)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .statdockGlassTile()
    }

    private func metricCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Theme.Typography.metric)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .statdockGlassTile()
    }
}
