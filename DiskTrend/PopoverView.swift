import SwiftUI
import AppKit
import Charts

struct PopoverView: View {
    @ObservedObject var diskMonitor: DiskMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(L10n.popoverTitle)
                    .font(.headline)
                Spacer()
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // All volumes
            ForEach(diskMonitor.volumes) { volume in
                VolumeRowView(volume: volume)
            }

            if diskMonitor.volumes.isEmpty {
                Text(L10n.popoverNoVolumes)
                    .foregroundColor(.secondary)
                    .padding()
            }

            // Trend
            if let trend = diskMonitor.trend {
                TrendView(trend: trend, snapshots: diskMonitor.historyManager?.recentSnapshots ?? [])
            }

            Divider()

            // Actions
            HStack {
                Button(action: { diskMonitor.refresh() }) {
                    Label(L10n.popoverRefresh, systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Spacer()

                Button(action: openSettings) {
                    Label(L10n.popoverSettings, systemImage: "gear")
                }
                .keyboardShortcut(",", modifiers: .command)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label(L10n.popoverQuit, systemImage: "power")
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(width: 320)
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: diskMonitor.lastUpdate, relativeTo: Date())
    }

    private func openSettings() {
        SettingsWindowController.shared.show(diskMonitor: diskMonitor)
    }
}

// Custom settings window because MenuBarExtra + Settings scene doesn't work well
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show(diskMonitor: DiskMonitor) {
        // Close all popovers/menu bar windows
        for window in NSApp.windows where window.className.contains("MenuBarExtra") || window.level == .popUpMenu {
            window.close()
        }

        if let window = window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(diskMonitor: diskMonitor)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = L10n.popoverSettings
        newWindow.styleMask = [.titled, .closable]
        newWindow.level = .floating
        newWindow.center()
        newWindow.setFrameAutosaveName("SettingsWindow")

        self.window = newWindow

        // Small delay to allow popover to close
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            newWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

struct VolumeRowView: View {
    let volume: VolumeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Volume name and icon
            HStack {
                Image(systemName: volumeIcon)
                    .foregroundColor(statusColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(volume.name)
                        .font(.system(.body, design: .default, weight: .medium))

                    Text(volume.mountPoint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Percentage
                Text(String(format: "%.1f%%", volume.usedPercentage))
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            // Statistics
            HStack(spacing: 16) {
                StatView(label: L10n.volumeTotal, value: volume.totalBytes.formattedBytes)
                StatView(label: L10n.volumeUsed, value: volume.usedBytes.formattedBytes)
                StatView(label: L10n.volumeFree, value: volume.freeBytes.formattedBytes, highlight: true)
            }
            .font(.caption)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))

                    // Used space
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressGradient)
                        .frame(width: geometry.size.width * CGFloat(volume.usedPercentage / 100))
                }
            }
            .frame(height: 8)
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private var volumeIcon: String {
        if volume.mountPoint == "/" {
            return "internaldrive.fill"
        } else if volume.isRemovable {
            return "externaldrive.fill"
        } else if volume.isInternal {
            return "internaldrive.fill"
        } else {
            return "externaldrive.fill"
        }
    }

    private var statusColor: Color {
        switch volume.status {
        case .healthy: return .green
        case .caution: return .yellow
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private var progressGradient: LinearGradient {
        let color = statusColor
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct StatView: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(highlight ? .semibold : .regular)
        }
    }
}

/// Data point for chart
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let freeGB: Double
}

struct TrendView: View {
    let trend: TrendInfo
    let snapshots: [DiskSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with trend indicator
            HStack(spacing: 6) {
                Image(systemName: trendIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(trendColor)

                Text(trend.localizedDescription)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(trendColor)

                Spacer()

                if let warning = trend.localizedWarning {
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(trend.daysUntilFull ?? 100 < 7 ? .red : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((trend.daysUntilFull ?? 100 < 7 ? Color.red : Color.orange).opacity(0.15))
                        .cornerRadius(4)
                }
            }

            // Chart
            if chartData.count >= 2 {
                Chart(chartData) { point in
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Free", point.freeGB)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [trendColor.opacity(0.3), trendColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Free", point.freeGB)
                    )
                    .foregroundStyle(trendColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel(format: .dateTime.hour())
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
                .chartYScale(domain: yAxisDomain)
                .frame(height: 60)
            }

            // Footer info
            HStack {
                Text(L10n.trendTitle(trend.periodHours))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(trend.dataPoints) pts")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }

    private var chartData: [ChartDataPoint] {
        snapshots.map { snapshot in
            ChartDataPoint(
                timestamp: snapshot.timestamp,
                freeGB: Double(snapshot.freeBytes) / 1_000_000_000
            )
        }
    }

    private var yAxisDomain: ClosedRange<Double> {
        guard let minVal = chartData.map({ $0.freeGB }).min(),
              let maxVal = chartData.map({ $0.freeGB }).max() else {
            return 0...100
        }
        let padding = max((maxVal - minVal) * 0.1, 1)
        return max(0, minVal - padding)...(maxVal + padding)
    }

    private var trendIcon: String {
        if trend.bytesPerDay > 1_000_000 {
            return "arrow.down.right"
        } else if trend.bytesPerDay < -1_000_000 {
            return "arrow.up.right"
        } else {
            return "arrow.right"
        }
    }

    private var trendColor: Color {
        if trend.bytesPerDay > 1_000_000_000 {
            return .red
        } else if trend.bytesPerDay > 100_000_000 {
            return .orange
        } else if trend.bytesPerDay > 1_000_000 {
            return .yellow
        } else if trend.bytesPerDay < -1_000_000 {
            return .green
        } else {
            return .gray
        }
    }
}

#Preview {
    PopoverView(diskMonitor: DiskMonitor())
}
