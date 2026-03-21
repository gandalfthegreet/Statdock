import SwiftUI

struct CPUPanel: View {
    @EnvironmentObject private var metrics: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("SYSTEM")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            Text("\(Int(metrics.cpuTotal))%")
                .font(Theme.Typography.metric)
                .foregroundStyle(Theme.ColorPalette.cpu)

            HStack {
                Text("Cores")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(metrics.physicalProcessorCount) physical · \(metrics.logicalProcessorCount) logical")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Active (est.)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(metrics.activeProcessorCoresEstimate) / \(metrics.logicalProcessorCount)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }

            Text("TOP PROCESSES")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            ForEach(metrics.topCPU) { row in
                HStack(alignment: .center, spacing: 6) {
                    Text(row.name)
                        .font(Theme.Typography.row)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(String(format: "%.1f%%", row.cpuPercent))
                        .font(Theme.Typography.row)
                        .foregroundStyle(Theme.ColorPalette.accent)
                        .monospacedDigit()
                    if AppProcessTermination.canRequestTermination(pid: row.id) {
                        Menu {
                            Button("Quit") { AppProcessTermination.terminate(pid: row.id) }
                            Button("Force Quit", role: .destructive) {
                                AppProcessTermination.forceTerminate(pid: row.id)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                }
                .padding(.vertical, 4)
            }

            if metrics.topCPU.isEmpty {
                Text("Collecting…")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
