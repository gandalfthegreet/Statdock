import SwiftUI

struct MemoryPanel: View {
    @EnvironmentObject private var metrics: MetricsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Memory", systemImage: "memorychip")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.secondary)
                Text("\(Int(metrics.memoryPercent))%")
                    .font(Theme.Typography.metric)
                    .foregroundStyle(Theme.ColorPalette.memory)
            }
            .padding(12)
            .statdockSectionCard()

            VStack(alignment: .leading, spacing: 4) {
                memoryRow("Total", byteString(metrics.totalMemoryBytes))
                memoryRow("Used", byteString(metrics.usedMemoryBytes))
                memoryRow("Free", byteString(metrics.freeMemoryBytes))
                memoryRow("Cached files", byteString(metrics.cachedFilesBytes))
                memoryRow("Compression", compressionLabel(metrics.memoryCompressionRatio))
                pressureRow
            }
            .padding(12)
            .statdockSectionCard()

            VStack(alignment: .leading, spacing: 6) {
                Label("Top by Memory", systemImage: "list.bullet.rectangle")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.secondary)

                ForEach(metrics.topMemory) { row in
                    HStack(alignment: .center, spacing: 6) {
                        Text(row.name)
                            .font(Theme.Typography.row)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(byteString(row.residentBytes))
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
            }
            .padding(12)
            .statdockSectionCard()
        }
    }

    private var pressureRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("Pressure")
                    .font(Theme.Typography.row)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(metrics.memoryPercent))%")
                    .font(Theme.Typography.row)
                    .foregroundStyle(Theme.ColorPalette.memory)
                    .monospacedDigit()
            }
            Text("Share of RAM: active, wired, and compressor store.")
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func memoryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.row)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(Theme.Typography.row)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
    }

    private func compressionLabel(_ ratio: Double?) -> String {
        guard let r = ratio, r > 0 else { return "—" }
        return String(format: "%.2f∶1 (logical∶physical)", r)
    }

    private func byteString(_ b: UInt64) -> String {
        let gb = Double(b) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        let mb = Double(b) / 1_048_576
        return String(format: "%.0f MB", mb)
    }
}
