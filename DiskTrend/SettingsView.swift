import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var diskMonitor: DiskMonitor
    @AppStorage("updateInterval") private var updateInterval: Double = 30
    @AppStorage("warningThreshold") private var warningThreshold: Double = 10
    @AppStorage("criticalThreshold") private var criticalThreshold: Double = 5
    @AppStorage("displayMode") private var displayMode: Int = 0
    @State private var launchAtLogin: Bool = false

    var body: some View {
        TabView {
            GeneralSettingsView(
                updateInterval: $updateInterval,
                displayMode: $displayMode,
                launchAtLogin: $launchAtLogin
            )
            .tabItem {
                Label(L10n.settingsGeneral, systemImage: "gear")
            }

            ThresholdSettingsView(
                warningThreshold: $warningThreshold,
                criticalThreshold: $criticalThreshold
            )
            .tabItem {
                Label(L10n.settingsAlerts, systemImage: "bell")
            }

            InfoView(diskMonitor: diskMonitor)
            .tabItem {
                Label(L10n.settingsInfo, systemImage: "chart.bar")
            }

            AboutView()
            .tabItem {
                Label(L10n.settingsAbout, systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 280)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

enum ChartPeriod: Int, CaseIterable {
    case days7 = 7
    case days14 = 14
    case days30 = 30

    var name: String {
        switch self {
        case .days7: return String(localized: "chart.period.7days")
        case .days14: return String(localized: "chart.period.14days")
        case .days30: return String(localized: "chart.period.30days")
        }
    }
}

enum AppearanceMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var name: String {
        switch self {
        case .system: return String(localized: "appearance.system")
        case .light: return String(localized: "appearance.light")
        case .dark: return String(localized: "appearance.dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var updateInterval: Double
    @Binding var displayMode: Int
    @Binding var launchAtLogin: Bool
    @AppStorage("decimalPlaces") private var decimalPlaces: Int = 1
    @AppStorage("iconStyle") private var iconStyle: Int = 0
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("chartPeriod") private var chartPeriod: Int = 14

    var body: some View {
        Form {
            Picker(L10n.settingsAppearance, selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Text(mode.name).tag(mode.rawValue)
                }
            }

            Picker(L10n.settingsChartPeriod, selection: $chartPeriod) {
                ForEach(ChartPeriod.allCases, id: \.rawValue) { period in
                    Text(period.name).tag(period.rawValue)
                }
            }

            Picker(L10n.settingsDisplayMode, selection: $displayMode) {
                ForEach(MenuBarDisplayMode.allCases, id: \.rawValue) { mode in
                    Text(mode.name).tag(mode.rawValue)
                }
            }

            Picker(L10n.settingsIconStyle, selection: $iconStyle) {
                ForEach(IconStyle.allCases, id: \.rawValue) { style in
                    Text(style.name).tag(style.rawValue)
                }
            }

            Picker(L10n.settingsUpdateInterval, selection: $updateInterval) {
                Text(L10n.settingsInterval10s).tag(10.0)
                Text(L10n.settingsInterval30s).tag(30.0)
                Text(L10n.settingsInterval1m).tag(60.0)
                Text(L10n.settingsInterval5m).tag(300.0)
            }

            Picker(L10n.settingsDecimals, selection: $decimalPlaces) {
                Text("0").tag(0)
                Text("1").tag(1)
                Text("2").tag(2)
            }

            Toggle(L10n.settingsLaunchAtLogin, isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Launch at login error: \(error)")
                    }
                }
        }
        .padding()
    }
}

struct ThresholdSettingsView: View {
    @Binding var warningThreshold: Double
    @Binding var criticalThreshold: Double

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading) {
                    Text(L10n.settingsWarningThreshold(Int(warningThreshold)))
                    Slider(value: $warningThreshold, in: 5...30, step: 1)
                }

                VStack(alignment: .leading) {
                    Text(L10n.settingsCriticalThreshold(Int(criticalThreshold)))
                    Slider(value: $criticalThreshold, in: 1...15, step: 1)
                }

                Text(L10n.settingsThresholdDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct InfoView: View {
    @ObservedObject var diskMonitor: DiskMonitor

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: L10n.infoMeasurements, value: "\(diskMonitor.historyManager?.recentSnapshots.count ?? 0)")

                InfoRow(label: L10n.infoVolumes, value: "\(diskMonitor.volumes.count)")

                if let trend = diskMonitor.trend {
                    InfoRow(label: L10n.infoTrendPeriod, value: "\(trend.periodHours)h")
                    InfoRow(label: L10n.infoDataPoints, value: "\(trend.dataPoints)")
                }

                if let firstSnapshot = diskMonitor.historyManager?.recentSnapshots.first {
                    InfoRow(label: L10n.infoFirstMeasurement, value: firstSnapshot.timestamp.formatted(date: .abbreviated, time: .shortened))
                }

                if let lastSnapshot = diskMonitor.historyManager?.recentSnapshots.last {
                    InfoRow(label: L10n.infoLastMeasurement, value: lastSnapshot.timestamp.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .padding()
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "internaldrive.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text(L10n.appName)
                .font(.title)
                .fontWeight(.bold)

            Text(L10n.appVersion("1.0.0"))
                .foregroundColor(.secondary)

            Text(L10n.appDescription)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingsView(diskMonitor: DiskMonitor())
}
