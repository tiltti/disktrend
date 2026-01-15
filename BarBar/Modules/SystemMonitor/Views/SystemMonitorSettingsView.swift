import SwiftUI

struct SystemMonitorSettingsView: View {
    @ObservedObject var module: SystemMonitorModule
    @AppStorage("updateInterval") private var updateInterval: Double = 30
    @AppStorage("warningThreshold") private var warningThreshold: Double = 10
    @AppStorage("criticalThreshold") private var criticalThreshold: Double = 5
    @AppStorage("chartPeriod") private var chartPeriod: Int = 14
    @AppStorage("decimalPlaces") private var decimalPlaces: Int = 1

    var body: some View {
        Form {
            Section {
                Toggle("Show CPU", isOn: $module.showCPU)
                Toggle("Show Memory", isOn: $module.showRAM)
                Toggle("Show Disk", isOn: $module.showDisk)
            } header: {
                Text("Visible Metrics")
            }

            Section {
                Picker("Update Interval", selection: $updateInterval) {
                    Text("10 seconds").tag(10.0)
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                    Text("5 minutes").tag(300.0)
                }

                Picker("Chart Period", selection: $chartPeriod) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }

                Picker("Decimal Places", selection: $decimalPlaces) {
                    Text("0").tag(0)
                    Text("1").tag(1)
                    Text("2").tag(2)
                }
            } header: {
                Text("Display")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Warning at \(Int(warningThreshold))% free")
                    Slider(value: $warningThreshold, in: 5...30, step: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Critical at \(Int(criticalThreshold))% free")
                    Slider(value: $criticalThreshold, in: 1...15, step: 1)
                }

                Text("Disk status colors change when free space drops below these thresholds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Disk Alerts")
            }
        }
        .formStyle(.grouped)
    }
}

struct SystemMonitorStatusView: View {
    @ObservedObject var module: SystemMonitorModule

    var body: some View {
        HStack(spacing: 6) {
            if module.showCPU {
                StatusBadge(
                    icon: "cpu",
                    value: "\(Int(module.cpuMonitor.usage))%",
                    color: cpuColor
                )
            }

            if module.showRAM {
                StatusBadge(
                    icon: "memorychip",
                    value: "\(Int(module.ramMonitor.usedPercentage))%",
                    color: ramColor
                )
            }

            if module.showDisk, let disk = module.diskMonitor.primaryVolume {
                StatusBadge(
                    icon: "internaldrive",
                    value: disk.freeBytes.formattedBytesShort,
                    color: diskColor
                )
            }
        }
    }

    private var cpuColor: Color {
        module.cpuMonitor.usage > 80 ? .red : (module.cpuMonitor.usage > 60 ? .orange : .green)
    }

    private var ramColor: Color {
        module.ramMonitor.usedPercentage > 90 ? .red : (module.ramMonitor.usedPercentage > 75 ? .orange : .green)
    }

    private var diskColor: Color {
        guard let disk = module.diskMonitor.primaryVolume else { return .gray }
        switch disk.status {
        case .critical: return .red
        case .warning: return .orange
        case .caution: return .yellow
        case .healthy: return .green
        }
    }
}

struct StatusBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
    }
}
