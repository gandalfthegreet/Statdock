import SwiftUI

struct OverviewPanel: View {
    @EnvironmentObject private var metrics: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            metricCard(title: "CPU", symbol: "cpu", value: "\(Int(metrics.cpuTotal))%", color: Theme.ColorPalette.cpu)
            metricCard(title: "Memory", symbol: "memorychip", value: "\(Int(metrics.memoryPercent))%", color: Theme.ColorPalette.memory)
            networkCard
            metricCard(
                title: "Battery",
                symbol: "battery.100",
                value: metrics.batteryInfo.map { "\($0.percent)%" } ?? "—",
                color: Theme.ColorPalette.battery
            )
        }
    }

    private var networkCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Network", systemImage: "arrow.up.arrow.down")
                .font(Theme.Typography.title)
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
        .statdockSectionCard()
    }

    private func metricCard(title: String, symbol: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(Theme.Typography.title)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Theme.Typography.metric)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .statdockSectionCard()
    }
}
