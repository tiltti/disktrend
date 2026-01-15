import SwiftUI

// MARK: - System Monitor Module

@MainActor
final class SystemMonitorModule: BarBarModule, ObservableObject {
    // MARK: - Module Identity

    static let moduleId = "system-monitor"
    static let moduleName = String(localized: "module.systemMonitor.name")
    static let moduleIcon = "gauge.with.dots.needle.bottom.50percent"
    static let moduleDescription = String(localized: "module.systemMonitor.description")

    // MARK: - Settings

    @AppStorage("systemMonitor.enabled") var isEnabled: Bool = true
    @AppStorage("systemMonitor.showCPU") var showCPU: Bool = true
    @AppStorage("systemMonitor.showRAM") var showRAM: Bool = true
    @AppStorage("systemMonitor.showDisk") var showDisk: Bool = true

    // MARK: - Monitors

    @Published var cpuMonitor = CPUMonitor()
    @Published var ramMonitor = RAMMonitor()
    @Published var diskMonitor = DiskMonitor()

    // MARK: - Status

    var statusSummary: String {
        var parts: [String] = []

        if showCPU {
            parts.append("CPU \(Int(cpuMonitor.usage))%")
        }
        if showRAM {
            parts.append("RAM \(Int(ramMonitor.usedPercentage))%")
        }
        if showDisk, let disk = diskMonitor.primaryVolume {
            parts.append(disk.freeBytes.formattedBytesShort)
        }

        return parts.isEmpty ? "System" : parts.joined(separator: " | ")
    }

    // MARK: - Lifecycle

    func onActivate() {
        cpuMonitor.startMonitoring()
        ramMonitor.startMonitoring()
        diskMonitor.startMonitoring()
    }

    func onDeactivate() {
        cpuMonitor.stopMonitoring()
        ramMonitor.stopMonitoring()
        diskMonitor.stopMonitoring()
    }

    func onAppWillTerminate() {
        onDeactivate()
    }

    // MARK: - Views

    func makeContentView() -> some View {
        SystemMonitorView(module: self)
    }

    func makeSettingsView() -> some View {
        SystemMonitorSettingsView(module: self)
    }

    func makeStatusView() -> some View {
        SystemMonitorStatusView(module: self)
    }
}
