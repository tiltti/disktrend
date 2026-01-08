import SwiftUI
import AppKit
import Charts

struct PopoverView: View {
    @ObservedObject var diskMonitor: DiskMonitor
    @AppStorage("chartPeriod") private var chartPeriod: Int = 14

    private var chartSnapshots: [DiskSnapshot] {
        guard let manager = diskMonitor.historyManager,
              let primary = diskMonitor.primaryVolume else { return [] }
        return manager.getAggregatedSnapshots(for: primary.mountPoint, days: chartPeriod)
    }

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
                TrendView(trend: trend, snapshots: chartSnapshots, chartPeriod: chartPeriod)
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
    let isForecast: Bool
}

struct TrendView: View {
    let trend: TrendInfo
    let snapshots: [DiskSnapshot]
    let chartPeriod: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with trend indicator
            HStack(spacing: 6) {
                Image(systemName: trendIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(statusColor)

                Text(trend.localizedDescription)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(statusColor)

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

            // Chart with forecast
            if historicalData.count >= 2 || forecastData.count >= 2 {
                Chart {
                    // Historical data - solid line
                    ForEach(historicalData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Free", point.freeGB),
                            series: .value("Series", "history")
                        )
                        .foregroundStyle(statusColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    // Now marker
                    if let lastHistorical = historicalData.last {
                        RuleMark(x: .value("Now", lastHistorical.timestamp))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                    }

                    // Forecast data - dashed line
                    ForEach(forecastData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Free", point.freeGB),
                            series: .value("Series", "forecast")
                        )
                        .foregroundStyle(forecastColor.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
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
                .chartYScale(domain: yAxisDomain)
                .frame(height: 60)
            }

            // Footer info
            HStack {
                Text(String(localized: "trend.historyDays \(chartPeriod)"))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if !forecastData.isEmpty {
                    Text(String(localized: "trend.forecast"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }

    private var historicalData: [ChartDataPoint] {
        snapshots.map { snapshot in
            ChartDataPoint(
                timestamp: snapshot.timestamp,
                freeGB: Double(snapshot.freeBytes) / 1_000_000_000,
                isForecast: false
            )
        }
    }

    private var forecastData: [ChartDataPoint] {
        guard let lastSnapshot = snapshots.last else { return [] }

        // Only show forecast if disk space is decreasing
        guard trend.bytesPerDay > 0 else { return [] }

        let lastFreeGB = Double(lastSnapshot.freeBytes) / 1_000_000_000
        let gbPerDay = Double(trend.bytesPerDay) / 1_000_000_000

        // Calculate days until full (max 30 days to show)
        let daysUntilFull = min(Int(ceil(lastFreeGB / gbPerDay)), 30)

        var forecast: [ChartDataPoint] = []

        // Start forecast from last data point
        forecast.append(ChartDataPoint(
            timestamp: lastSnapshot.timestamp,
            freeGB: lastFreeGB,
            isForecast: true
        ))

        // Add forecast points until disk full or 30 days
        for day in 1...daysUntilFull {
            let forecastDate = Calendar.current.date(byAdding: .day, value: day, to: lastSnapshot.timestamp) ?? lastSnapshot.timestamp
            let forecastGB = max(0, lastFreeGB - (gbPerDay * Double(day)))

            forecast.append(ChartDataPoint(
                timestamp: forecastDate,
                freeGB: forecastGB,
                isForecast: true
            ))

            // Stop if disk would be full
            if forecastGB <= 0 { break }
        }

        return forecast
    }

    private var allChartData: [ChartDataPoint] {
        historicalData + forecastData
    }

    private var yAxisDomain: ClosedRange<Double> {
        let allData = allChartData
        guard let minVal = allData.map({ $0.freeGB }).min(),
              let maxVal = allData.map({ $0.freeGB }).max() else {
            return 0...100
        }
        let padding = max((maxVal - minVal) * 0.1, 5)
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

    // Color based on current disk status (like the volume indicator)
    private var statusColor: Color {
        guard let lastSnapshot = snapshots.last else { return .gray }
        let freePercent = Double(lastSnapshot.freeBytes) / Double(lastSnapshot.totalBytes) * 100

        if freePercent < 5 { return .red }
        if freePercent < 10 { return .orange }
        if freePercent < 20 { return .yellow }
        return .green
    }

    // Forecast line color based on predicted outcome
    private var forecastColor: Color {
        guard let days = trend.daysUntilFull else { return statusColor }
        if days < 7 { return .red }
        if days < 14 { return .orange }
        if days < 30 { return .yellow }
        return statusColor
    }
}

#Preview {
    PopoverView(diskMonitor: DiskMonitor())
}
