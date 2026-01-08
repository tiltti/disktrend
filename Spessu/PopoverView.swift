import SwiftUI

struct PopoverView: View {
    @ObservedObject var diskMonitor: DiskMonitor
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Otsikko
            HStack {
                Text("Spessu")
                    .font(.headline)
                Spacer()
                Text("Päivitetty: \(timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Kaikki levyt
            ForEach(diskMonitor.volumes) { volume in
                VolumeRowView(volume: volume)
            }

            if diskMonitor.volumes.isEmpty {
                Text("Ei levyjä löytynyt")
                    .foregroundColor(.secondary)
                    .padding()
            }

            // Trendi
            if let trend = diskMonitor.trend {
                TrendView(trend: trend)
            }

            Divider()

            // Toiminnot
            HStack {
                Button(action: { diskMonitor.refresh() }) {
                    Label("Päivitä", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Spacer()

                Button(action: { openSettings() }) {
                    Label("Asetukset", systemImage: "gear")
                }
                .keyboardShortcut(",", modifiers: .command)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label("Lopeta", systemImage: "power")
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
}

struct VolumeRowView: View {
    let volume: VolumeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Levyn nimi ja ikoni
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

                // Prosentti
                Text(String(format: "%.1f%%", volume.usedPercentage))
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            // Tilastot
            HStack(spacing: 16) {
                StatView(label: "Yhteensä", value: volume.totalBytes.formattedBytes)
                StatView(label: "Käytetty", value: volume.usedBytes.formattedBytes)
                StatView(label: "Vapaa", value: volume.freeBytes.formattedBytes, highlight: true)
            }
            .font(.caption)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Tausta
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))

                    // Käytetty tila
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

struct TrendView: View {
    let trend: TrendInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                Text("Trendi (\(trend.periodHours)h)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Muutos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trend.trendDescription)
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundColor(trendColor)
                }

                if let warning = trend.fullWarning {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Arvio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(trend.daysUntilFull ?? 100 < 7 ? .red : .secondary)
                    }
                }

                Spacer()

                Text("\(trend.dataPoints) mittausta")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }

    private var trendIcon: String {
        if trend.bytesPerDay > 1_000_000 { // > 1 MB/päivä vähenee
            return "arrow.down.circle.fill"
        } else if trend.bytesPerDay < -1_000_000 { // > 1 MB/päivä kasvaa
            return "arrow.up.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }

    private var trendColor: Color {
        if trend.bytesPerDay > 1_000_000_000 { // > 1 GB/päivä vähenee
            return .red
        } else if trend.bytesPerDay > 100_000_000 { // > 100 MB/päivä vähenee
            return .orange
        } else if trend.bytesPerDay > 1_000_000 { // > 1 MB/päivä vähenee
            return .yellow
        } else if trend.bytesPerDay < -1_000_000 { // kasvaa
            return .green
        } else {
            return .gray
        }
    }
}

#Preview {
    PopoverView(diskMonitor: DiskMonitor())
}
