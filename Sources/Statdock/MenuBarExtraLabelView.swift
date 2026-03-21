import SwiftUI

/// Menu bar icon, optionally with live text from `AppSettings` metric toggles.
struct MenuBarExtraLabelView: View {
    @EnvironmentObject private var metrics: MetricsStore
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Group {
            if settings.menuBarLiveInfoEnabled {
                HStack(spacing: 4) {
                    Image(systemName: "chart.xyaxis.line")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.small)
                    if settings.metricVisibility.anyEnabled {
                        Text(line)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                }
                .accessibilityLabel(settings.metricVisibility.anyEnabled ? "Statdock, \(line)" : "Statdock")
            } else {
                Image(systemName: "chart.xyaxis.line")
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel("Statdock")
            }
        }
    }

    private var line: String {
        let v = settings.metricVisibility
        var parts: [String] = []
        if v.cpu {
            parts.append("CPU \(Int(metrics.cpuTotal))%")
        }
        if v.memory {
            parts.append("MEM \(Int(metrics.memoryPercent))%")
        }
        if v.battery {
            parts.append("BAT " + (metrics.batteryInfo.map { "\($0.percent)%" } ?? "—"))
        }
        if v.network {
            let d = Theme.throughputString(metrics.networkDownBps)
            let u = Theme.throughputString(metrics.networkUpBps)
            parts.append("↓\(d) ↑\(u)")
        }
        return parts.joined(separator: " · ")
    }
}
