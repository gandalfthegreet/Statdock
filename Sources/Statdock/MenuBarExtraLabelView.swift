import SwiftUI

/// Menu bar icon, optionally with live text from `AppSettings` metric toggles.
struct MenuBarExtraLabelView: View {
    @EnvironmentObject private var metrics: MetricsStore
    @EnvironmentObject private var settings: AppSettings
    
    private struct MetricSegment: Identifiable {
        let id: String
        let value: String
        let accessibility: String
    }

    var body: some View {
        Group {
            if settings.menuBarLiveInfoEnabled {
                HStack(spacing: 4) {
                    Image(systemName: "chart.xyaxis.line")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.small)
                    if settings.metricVisibility.anyEnabled {
                        Text(menuBarLine)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                }
                .accessibilityLabel(settings.metricVisibility.anyEnabled ? "Statdock, \(accessibilityLine)" : "Statdock")
            } else {
                Image(systemName: "chart.xyaxis.line")
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel("Statdock")
            }
        }
    }

    private var metricSegments: [MetricSegment] {
        let v = settings.metricVisibility
        var parts: [MetricSegment] = []
        if v.cpu {
            let value = "\(Int(metrics.cpuTotal))%"
            parts.append(MetricSegment(id: "cpu", value: "CPU \(value)", accessibility: "CPU \(value)"))
        }
        if v.memory {
            let value = "\(Int(metrics.memoryPercent))%"
            parts.append(MetricSegment(id: "memory", value: "MEM \(value)", accessibility: "Memory \(value)"))
        }
        if v.battery {
            let value = metrics.batteryInfo.map { "\($0.percent)%" } ?? "—"
            parts.append(MetricSegment(id: "battery", value: "BAT \(value)", accessibility: "Battery \(value)"))
        }
        if v.network {
            let d = compactThroughputString(metrics.networkDownBps)
            let u = compactThroughputString(metrics.networkUpBps)
            let value = "NET \(d)/\(u)"
            parts.append(MetricSegment(id: "network", value: value, accessibility: "Network down \(d), up \(u)"))
        }
        return parts
    }

    private var menuBarLine: String {
        metricSegments.map(\.value).joined(separator: " · ")
    }

    private var accessibilityLine: String {
        metricSegments.map(\.accessibility).joined(separator: ", ")
    }

    private func compactThroughputString(_ bps: Double) -> String {
        if bps >= 1_048_576 {
            return String(format: "%.1fM", bps / 1_048_576)
        }
        if bps >= 1024 {
            return String(format: "%.0fK", bps / 1024)
        }
        return String(format: "%.0fB", bps)
    }
}
