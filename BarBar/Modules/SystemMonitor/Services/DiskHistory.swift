import Foundation
import SwiftData

// MARK: - Disk Snapshot Model

@Model
final class DiskSnapshot {
    var timestamp: Date
    var volumeName: String
    var mountPoint: String
    var totalBytes: Int64
    var freeBytes: Int64

    var usedBytes: Int64 { totalBytes - freeBytes }
    var usedPercentage: Double { Double(usedBytes) / Double(totalBytes) * 100 }

    init(timestamp: Date = Date(), volumeName: String, mountPoint: String, totalBytes: Int64, freeBytes: Int64) {
        self.timestamp = timestamp
        self.volumeName = volumeName
        self.mountPoint = mountPoint
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
    }

    convenience init(from volume: VolumeInfo) {
        self.init(
            timestamp: Date(),
            volumeName: volume.name,
            mountPoint: volume.mountPoint,
            totalBytes: volume.totalBytes,
            freeBytes: volume.freeBytes
        )
    }
}

// MARK: - Trend Info

struct TrendInfo {
    let bytesPerHour: Int64
    let bytesPerDay: Int64
    let daysUntilFull: Double?
    let dataPoints: Int
    let periodHours: Int

    var isIncreasing: Bool { bytesPerDay < 0 }
    var isDecreasing: Bool { bytesPerDay > 0 }

    var localizedDescription: String {
        if bytesPerDay == 0 {
            return String(localized: "trend.stable")
        } else if bytesPerDay > 0 {
            return "-\(bytesPerDay.formattedBytes)/\(String(localized: "day"))"
        } else {
            return "+\(abs(bytesPerDay).formattedBytes)/\(String(localized: "day"))"
        }
    }

    var localizedWarning: String? {
        guard let days = daysUntilFull, days > 0 && days < 30 else { return nil }

        if days < 1 {
            return String(localized: "trend.fullIn24h")
        } else if days < 7 {
            return String(format: String(localized: "trend.fullInDays"), Int(days))
        } else {
            return String(format: String(localized: "trend.fullInDaysNormal"), Int(days))
        }
    }
}

// MARK: - History Manager

@MainActor
class DiskHistoryManager: ObservableObject {
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    @Published var recentSnapshots: [DiskSnapshot] = []
    @Published var trend: TrendInfo?

    init() {
        setupSwiftData()
    }

    private func setupSwiftData() {
        do {
            let schema = Schema([DiskSnapshot.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer?.mainContext
            print("[SwiftData] Initialized successfully")
        } catch {
            print("[SwiftData] Error: \(error)")
        }
    }

    func saveSnapshots(volumes: [VolumeInfo]) {
        guard let context = modelContext else { return }

        for volume in volumes {
            let snapshot = DiskSnapshot(from: volume)
            context.insert(snapshot)
        }

        do {
            try context.save()
            print("[History] Saved \(volumes.count) snapshots")
        } catch {
            print("[History] Save error: \(error)")
        }
    }

    func getSnapshots(for mountPoint: String, hours: Int = 24) -> [DiskSnapshot] {
        guard let context = modelContext else { return [] }

        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()

        let predicate = #Predicate<DiskSnapshot> { snapshot in
            snapshot.mountPoint == mountPoint && snapshot.timestamp >= startDate
        }

        let descriptor = FetchDescriptor<DiskSnapshot>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("[History] Fetch error: \(error)")
            return []
        }
    }

    func getSnapshots(for mountPoint: String, days: Int) -> [DiskSnapshot] {
        return getSnapshots(for: mountPoint, hours: days * 24)
    }

    func getAggregatedSnapshots(for mountPoint: String, days: Int) -> [DiskSnapshot] {
        let allSnapshots = getSnapshots(for: mountPoint, days: days)

        if days <= 3 {
            return allSnapshots
        }

        var hourlySnapshots: [DiskSnapshot] = []
        let calendar = Calendar.current

        var grouped: [Date: [DiskSnapshot]] = [:]
        for snapshot in allSnapshots {
            let hourStart = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: snapshot.timestamp)) ?? snapshot.timestamp
            grouped[hourStart, default: []].append(snapshot)
        }

        for (_, snapshots) in grouped.sorted(by: { $0.key < $1.key }) {
            if let last = snapshots.last {
                hourlySnapshots.append(last)
            }
        }

        return hourlySnapshots.sorted { $0.timestamp < $1.timestamp }
    }

    func calculateTrend(for mountPoint: String) -> TrendInfo? {
        let snapshots = getSnapshots(for: mountPoint, hours: 24)

        guard snapshots.count >= 2,
              let first = snapshots.first,
              let last = snapshots.last else {
            return nil
        }

        let timeDiff = last.timestamp.timeIntervalSince(first.timestamp)
        guard timeDiff > 0 else { return nil }

        let bytesDiff = first.freeBytes - last.freeBytes
        let bytesPerHour = Double(bytesDiff) / (timeDiff / 3600)

        var daysUntilFull: Double? = nil
        if bytesPerHour > 0 && last.freeBytes > 0 {
            let hoursUntilFull = Double(last.freeBytes) / bytesPerHour
            daysUntilFull = hoursUntilFull / 24
        }

        return TrendInfo(
            bytesPerHour: Int64(bytesPerHour),
            bytesPerDay: Int64(bytesPerHour * 24),
            daysUntilFull: daysUntilFull,
            dataPoints: snapshots.count,
            periodHours: Int(timeDiff / 3600)
        )
    }

    func refreshTrend(for mountPoint: String) {
        trend = calculateTrend(for: mountPoint)
        recentSnapshots = getSnapshots(for: mountPoint, hours: 24)
    }

    func cleanupOldSnapshots() {
        guard let context = modelContext else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let predicate = #Predicate<DiskSnapshot> { snapshot in
            snapshot.timestamp < cutoffDate
        }

        let descriptor = FetchDescriptor<DiskSnapshot>(predicate: predicate)

        do {
            let oldSnapshots = try context.fetch(descriptor)
            for snapshot in oldSnapshots {
                context.delete(snapshot)
            }
            try context.save()
            print("[History] Cleaned up \(oldSnapshots.count) old snapshots")
        } catch {
            print("[History] Cleanup error: \(error)")
        }
    }
}
