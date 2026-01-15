import SwiftUI
import Charts

// MARK: - Main System Monitor View

struct SystemMonitorView: View {
    @ObservedObject var module: SystemMonitorModule
    @State private var selectedTab: SystemTab = .overview

    enum SystemTab: String, CaseIterable {
        case overview = "overview"
        case cpu = "cpu"
        case memory = "memory"
        case disk = "disk"

        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            case .disk: return "internaldrive"
            }
        }

        var name: String {
            switch self {
            case .overview: return String(localized: "tab.overview")
            case .cpu: return "CPU"
            case .memory: return "RAM"
            case .disk: return String(localized: "tab.disk")
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("", selection: $selectedTab) {
                ForEach(SystemTab.allCases, id: \.self) { tab in
                    Label(tab.name, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            // Content
            ScrollView {
                switch selectedTab {
                case .overview:
                    OverviewView(module: module)
                case .cpu:
                    CPUDetailView(monitor: module.cpuMonitor)
                case .memory:
                    RAMDetailView(monitor: module.ramMonitor)
                case .disk:
                    DiskDetailView(monitor: module.diskMonitor)
                }
            }
            .padding()
        }
    }
}

// MARK: - Overview View

struct OverviewView: View {
    @ObservedObject var module: SystemMonitorModule

    var body: some View {
        VStack(spacing: 12) {
            // CPU Card
            if module.showCPU {
                MetricCard(
                    title: "CPU",
                    icon: "cpu",
                    value: "\(Int(module.cpuMonitor.usage))%",
                    color: cpuColor
                ) {
                    HStack {
                        Text("User: \(Int(module.cpuMonitor.userUsage))%")
                        Spacer()
                        Text("System: \(Int(module.cpuMonitor.systemUsage))%")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            // RAM Card
            if module.showRAM {
                MetricCard(
                    title: "RAM",
                    icon: "memorychip",
                    value: "\(Int(module.ramMonitor.usedPercentage))%",
                    color: ramColor
                ) {
                    HStack {
                        Text("Used: \(ByteFormatter.formatShort(module.ramMonitor.usedBytes))")
                        Spacer()
                        Text("Free: \(ByteFormatter.formatShort(module.ramMonitor.freeBytes))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            // Disk Card
            if module.showDisk, let disk = module.diskMonitor.primaryVolume {
                MetricCard(
                    title: disk.name,
                    icon: "internaldrive",
                    value: "\(Int(disk.usedPercentage))%",
                    color: diskColor(for: disk)
                ) {
                    HStack {
                        Text("Used: \(disk.usedBytes.formattedBytesShort)")
                        Spacer()
                        Text("Free: \(disk.freeBytes.formattedBytesShort)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private var cpuColor: Color {
        let usage = module.cpuMonitor.usage
        if usage > 80 { return .red }
        if usage > 60 { return .orange }
        if usage > 40 { return .yellow }
        return .green
    }

    private var ramColor: Color {
        let usage = module.ramMonitor.usedPercentage
        if usage > 90 { return .red }
        if usage > 75 { return .orange }
        if usage > 50 { return .yellow }
        return .green
    }

    private func diskColor(for volume: VolumeInfo) -> Color {
        switch volume.status {
        case .critical: return .red
        case .warning: return .orange
        case .caution: return .yellow
        case .healthy: return .green
        }
    }
}

// MARK: - Metric Card

struct MetricCard<Content: View>: View {
    let title: String
    let icon: String
    let value: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)

                Spacer()

                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(color)
            }

            ProgressView(value: Double(value.replacingOccurrences(of: "%", with: "")) ?? 0, total: 100)
                .tint(color)

            content()
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - CPU Detail View

struct CPUDetailView: View {
    @ObservedObject var monitor: CPUMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cpu")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("CPU Usage")
                        .font(.headline)
                    Text("\(monitor.coreCount) cores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(monitor.usage))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(usageColor)
            }

            Divider()

            // Breakdown
            VStack(spacing: 12) {
                UsageRow(label: "User", value: monitor.userUsage, color: .blue)
                UsageRow(label: "System", value: monitor.systemUsage, color: .purple)
                UsageRow(label: "Idle", value: monitor.idleUsage, color: .gray)
            }

            Spacer()

            // Last update
            Text("Updated: \(monitor.lastUpdate.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var usageColor: Color {
        if monitor.usage > 80 { return .red }
        if monitor.usage > 60 { return .orange }
        return .blue
    }
}

// MARK: - RAM Detail View

struct RAMDetailView: View {
    @ObservedObject var monitor: RAMMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "memorychip")
                    .font(.largeTitle)
                    .foregroundColor(.orange)

                VStack(alignment: .leading) {
                    Text("Memory Usage")
                        .font(.headline)
                    Text("Total: \(ByteFormatter.formatShort(monitor.totalBytes))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(monitor.usedPercentage))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(usageColor)
            }

            Divider()

            // Breakdown
            VStack(spacing: 12) {
                MemoryRow(label: "Active", bytes: monitor.activeBytes, color: .blue)
                MemoryRow(label: "Wired", bytes: monitor.wiredBytes, color: .orange)
                MemoryRow(label: "Compressed", bytes: monitor.compressedBytes, color: .purple)
                MemoryRow(label: "Free", bytes: monitor.freeBytes, color: .green)
            }

            Spacer()

            // Last update
            Text("Updated: \(monitor.lastUpdate.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var usageColor: Color {
        if monitor.usedPercentage > 90 { return .red }
        if monitor.usedPercentage > 75 { return .orange }
        return .orange
    }
}

// MARK: - Disk Detail View

struct DiskDetailView: View {
    @ObservedObject var monitor: DiskMonitor
    @AppStorage("chartPeriod") private var chartPeriod: Int = 14

    private var chartSnapshots: [DiskSnapshot] {
        guard let manager = monitor.historyManager,
              let primary = monitor.primaryVolume else { return [] }
        return manager.getAggregatedSnapshots(for: primary.mountPoint, days: chartPeriod)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // All volumes
            ForEach(monitor.volumes) { volume in
                VolumeRow(volume: volume)
            }

            if monitor.volumes.isEmpty {
                Text("No volumes found")
                    .foregroundColor(.secondary)
            }

            // Trend chart (if available)
            if let trend = monitor.trend, !chartSnapshots.isEmpty {
                Divider()
                TrendChartView(trend: trend, snapshots: chartSnapshots, chartPeriod: chartPeriod)
            }

            Spacer()

            // Last update
            Text("Updated: \(monitor.lastUpdate.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Helper Views

struct UsageRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(Int(value))%")
                .fontWeight(.medium)
            ProgressView(value: value, total: 100)
                .frame(width: 100)
                .tint(color)
        }
    }
}

struct MemoryRow: View {
    let label: String
    let bytes: UInt64
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(ByteFormatter.formatShort(bytes))
                .fontWeight(.medium)
        }
    }
}

struct VolumeRow: View {
    let volume: VolumeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: volume.mountPoint == "/" ? "internaldrive.fill" : "externaldrive.fill")
                    .foregroundColor(statusColor)

                VStack(alignment: .leading) {
                    Text(volume.name)
                        .fontWeight(.medium)
                    Text(volume.mountPoint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(volume.usedPercentage))%")
                    .font(.headline)
                    .foregroundColor(statusColor)
            }

            ProgressView(value: volume.usedPercentage, total: 100)
                .tint(statusColor)

            HStack {
                Text("Used: \(volume.usedBytes.formattedBytesShort)")
                Spacer()
                Text("Free: \(volume.freeBytes.formattedBytesShort)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        switch volume.status {
        case .healthy: return .green
        case .caution: return .yellow
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Trend Chart View

struct TrendChartView: View {
    let trend: TrendInfo
    let snapshots: [DiskSnapshot]
    let chartPeriod: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trend.localizedDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if let warning = trend.localizedWarning {
                    Text(warning)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            if snapshots.count >= 2 {
                Chart {
                    ForEach(snapshots, id: \.timestamp) { snapshot in
                        LineMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value("Free", Double(snapshot.freeBytes) / 1_000_000_000)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel {
                            if let gb = value.as(Double.self) {
                                Text("\(Int(gb))G")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 80)
            }

            Text("\(chartPeriod) days history")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }
}
