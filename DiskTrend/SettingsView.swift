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

            AboutView()
            .tabItem {
                Label(L10n.settingsAbout, systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 250)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var updateInterval: Double
    @Binding var displayMode: Int
    @Binding var launchAtLogin: Bool
    @AppStorage("decimalPlaces") private var decimalPlaces: Int = 1
    @AppStorage("iconStyle") private var iconStyle: Int = 0

    var body: some View {
        Form {
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
