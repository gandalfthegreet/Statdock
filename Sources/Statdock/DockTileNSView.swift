import AppKit

/// AppKit drawing for `NSDockTile.contentView` (reliable vs SwiftUI in Dock tiles).
final class DockTileNSView: NSView {
    private weak var metrics: MetricsStore?
    private var visible = MetricVisibility(cpu: true, memory: true, battery: true, network: true)

    override var isOpaque: Bool { false }

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMetrics(_ m: MetricsStore, visible: MetricVisibility) {
        metrics = m
        self.visible = visible
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bounds = self.bounds
        let w = bounds.width
        let h = bounds.height

        let icon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        icon.draw(in: bounds, from: NSRect.zero, operation: .copy, fraction: 1.0, respectFlipped: true, hints: nil)

        let grad = NSGradient(colors: [.clear, NSColor.black.withAlphaComponent(0.55)], atLocations: [0, 1], colorSpace: NSColorSpace.deviceRGB)
        let gradRect = NSRect(x: 0, y: h * 0.42, width: w, height: h * 0.58)
        grad?.draw(in: gradRect, angle: -90)

        guard let m = metrics else { return }

        var rows: [(String, String)] = []
        if visible.cpu {
            rows.append(("CPU", "\(Int(m.cpuTotal))%"))
        }
        if visible.memory {
            rows.append(("MEM", "\(Int(m.memoryPercent))%"))
        }
        if visible.battery {
            rows.append(("BAT", m.batteryInfo.map { "\($0.percent)%" } ?? "—"))
        }
        if visible.network {
            rows.append(("", shortNet(down: m.networkDownBps, up: m.networkUpBps)))
        }

        let rowCount = rows.count
        guard rowCount > 0 else { return }

        let compact = rowCount >= 3
        let keySize: CGFloat = compact ? 6.5 : 7
        let bodySize: CGFloat = compact ? 7.5 : 8
        let body: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: bodySize, weight: .semibold),
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black.withAlphaComponent(0.88),
            .strokeWidth: -2,
        ]
        let keyBody: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: keySize, weight: .bold),
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black.withAlphaComponent(0.88),
            .strokeWidth: -2,
        ]

        let pad: CGFloat = 7
        var lineY = h - pad

        if rowCount == 1, let only = rows.first {
            let big: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: NSColor.white,
                .strokeColor: NSColor.black.withAlphaComponent(0.9),
                .strokeWidth: -3,
            ]
            let sub: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: NSColor.white,
                .strokeColor: NSColor.black.withAlphaComponent(0.88),
                .strokeWidth: -2,
            ]
            if only.0.isEmpty {
                let va = NSAttributedString(string: only.1, attributes: big)
                lineY -= va.size().height
                va.draw(at: NSPoint(x: pad, y: lineY))
                return
            }
            let va = NSAttributedString(string: only.1, attributes: big)
            let sa = NSAttributedString(string: only.0, attributes: sub)
            lineY -= sa.size().height
            sa.draw(at: NSPoint(x: pad, y: lineY))
            lineY -= 4
            lineY -= va.size().height
            va.draw(at: NSPoint(x: pad, y: lineY))
            return
        }

        for row in rows {
            let vs = NSAttributedString(string: row.1, attributes: body)
            if row.0.isEmpty {
                lineY -= vs.size().height
                vs.draw(at: NSPoint(x: pad, y: lineY))
                lineY -= 2
            } else {
                let ks = NSAttributedString(string: row.0, attributes: keyBody)
                let rowH = max(ks.size().height, vs.size().height)
                lineY -= rowH
                ks.draw(at: NSPoint(x: pad, y: lineY))
                vs.draw(at: NSPoint(x: pad + 26, y: lineY))
                lineY -= 2
            }
        }
    }

    private func shortNet(down: Double, up: Double) -> String {
        let d = Theme.throughputString(down)
        let u = Theme.throughputString(up)
        return "↓\(d) ↑\(u)"
    }
}
