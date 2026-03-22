import SwiftUI

struct MainPopoverView: View {
    @EnvironmentObject private var metrics: MetricsStore
    @EnvironmentObject private var settings: AppSettings
    @State private var tab: StatdockPanel = .overview

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Statdock")
                        .font(Theme.Typography.header)
                    Spacer()
                    Text("Live")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .center, spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(StatdockPanel.allCases) { t in
                                tabButton(t)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    Button {
                        NotificationCenter.default.post(name: .statdockOpenSettings, object: nil)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background {
                                Circle()
                                    .fill(Color.primary.opacity(0.06))
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Settings (⌘,)")
                }
            }
            .padding(10)
            .statdockSectionCard()
            .padding(.horizontal, 10)
            .padding(.top, 10)

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
        .frame(width: 390, height: 440)
        .background(.regularMaterial)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    private func tabButton(_ t: StatdockPanel) -> some View {
        let on = tab == t
        return Button {
            tab = t
        } label: {
            HStack(spacing: 4) {
                Image(systemName: t.symbolName)
                    .font(.system(size: 11, weight: .semibold))
                Text(t.rawValue)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(on ? Color.primary : Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(on ? Color.accentColor.opacity(0.18) : Color.clear)
                }
        }
        .buttonStyle(.plain)
    }
}
