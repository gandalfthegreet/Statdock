import SwiftUI

struct NetworkPanel: View {
    @EnvironmentObject private var metrics: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("TOP PROCESSES (NETTOP)")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

            Text(
                "Rates are averages since the last refresh (longer intervals smooth bursts). Includes system daemons and apps. Last non-zero list is kept briefly if a sample is empty."
            )
            .font(.system(size: 9, weight: .regular))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

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
    }
}
