import SwiftUI

struct MainPopoverView: View {
    @EnvironmentObject private var metrics: MetricsStore
    @EnvironmentObject private var settings: AppSettings
    @State private var tab: StatdockPanel = .overview

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(StatdockPanel.allCases) { t in
                            tabButton(t)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                Button {
                    NotificationCenter.default.post(name: .statdockOpenSettings, object: nil)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Settings (⌘,)")
            }
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider()
                .overlay(Color.primary.opacity(0.12))

            ScrollView {
                Group {
                    switch tab {
                    case .overview: OverviewPanel()
                    case .cpu: CPUPanel()
                    case .memory: MemoryPanel()
                    case .battery: BatteryPanel()
                    case .network: NetworkPanel()
                    }
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 360, height: 380)
        .background(.regularMaterial)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    private func tabButton(_ t: StatdockPanel) -> some View {
        let on = tab == t
        return Button {
            tab = t
        } label: {
            Text(t.rawValue)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(on ? Color.primary : Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(on ? Color.accentColor.opacity(0.22) : Color.clear)
                }
        }
        .buttonStyle(.plain)
    }
}
