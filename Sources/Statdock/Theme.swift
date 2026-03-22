import SwiftUI

/// Statdock visual tokens — materials + metric tints (adapts with light/dark).
enum Theme {
    /// Vibrant tints for metrics (readable on glass in both modes).
    enum ColorPalette {
        static let accent = Color(red: 0.25, green: 0.55, blue: 0.95)
        static let cpu = Color(red: 0.35, green: 0.55, blue: 1.0)
        static let memory = Color(red: 0.65, green: 0.45, blue: 0.98)
        static let network = Color(red: 0.25, green: 0.78, blue: 0.52)
        static let battery = Color(red: 0.35, green: 0.82, blue: 0.45)
    }

    enum Typography {
        static let header = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let title = Font.system(size: 13, weight: .semibold, design: .rounded)
        static let metric = Font.system(size: 28, weight: .bold, design: .rounded)
        static let caption = Font.system(size: 10, weight: .medium, design: .rounded)
        static let row = Font.system(size: 11, weight: .medium, design: .default)
    }

    static let cornerRadius: CGFloat = 12
    static let spacing: CGFloat = 8
    static let sectionRadius: CGFloat = 14

    static func throughputString(_ bps: Double) -> String {
        if bps >= 1_048_576 { return String(format: "%.1f MB/s", bps / 1_048_576) }
        if bps >= 1024 { return String(format: "%.0f KB/s", bps / 1024) }
        return String(format: "%.0f B/s", bps)
    }
}

extension View {
    /// Frosted “glass” tile: material fill + hairline border (Apple-style continuous corners).
    func statdockGlassTile(cornerRadius: CGFloat = Theme.cornerRadius) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        }
    }

    func statdockSectionCard() -> some View {
        statdockGlassTile(cornerRadius: Theme.sectionRadius)
            .padding(.bottom, 2)
    }
}
