import SwiftUI

struct NetworkPanel: View {
    @EnvironmentObject private var metrics: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Network", systemImage: "arrow.up.arrow.down")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label(Theme.throughputString(metrics.networkDownBps), systemImage: "arrow.down.circle")
                        .font(Theme.Typography.row)
                        .foregroundStyle(Theme.ColorPalette.network)
                    Label(Theme.throughputString(metrics.networkUpBps), systemImage: "arrow.up.circle")
                        .font(Theme.Typography.row)
                        .foregroundStyle(Theme.ColorPalette.accent)
                }
                .labelStyle(.titleAndIcon)
                Text("Rates are smoothed between refreshes; short bursts may appear dampened.")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .statdockSectionCard()

            VStack(alignment: .leading, spacing: 6) {
                Label("Top Processes (nettop)", systemImage: "list.bullet.rectangle")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.secondary)

                ForEach(metrics.topNetwork) { row in
                    HStack {
                        Text(row.displayName)
                            .font(Theme.Typography.row)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                        Text(Theme.throughputString(row.bytesPerSecond))
                            .font(Theme.Typography.row)
                            .foregroundStyle(Theme.ColorPalette.network)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 4)
                }

                if metrics.topNetwork.isEmpty {
                    Text("Waiting for the first nettop sample…")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .statdockSectionCard()
        }
    }
}
