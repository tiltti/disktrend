import Foundation
import SwiftData

/// Yksittäinen levytilan mittaus
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

    /// Luo snapshot VolumeInfo:sta
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

/// Historian hallinta
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
            print("✅ SwiftData alustettu")
        } catch {
            print("❌ SwiftData virhe: \(error)")
        }
    }

    /// Tallenna snapshot kaikista levyistä
    func saveSnapshots(volumes: [VolumeInfo]) {
        guard let context = modelContext else { return }

        for volume in volumes {
            let snapshot = DiskSnapshot(from: volume)
            context.insert(snapshot)
        }

        do {
            try context.save()
            print("💾 Tallennettu \(volumes.count) snapshotia")
        } catch {
            print("❌ Tallennus virhe: \(error)")
        }
    }

    /// Hae viimeisimmät snapshotit tietylle levylle
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
            print("❌ Haku virhe: \(error)")
            return []
        }
    }

    /// Laske trendi päälevylle
    func calculateTrend(for mountPoint: String) -> TrendInfo? {
        let snapshots = getSnapshots(for: mountPoint, hours: 24)

        guard snapshots.count >= 2,
              let first = snapshots.first,
              let last = snapshots.last else {
            return nil
        }

        let timeDiff = last.timestamp.timeIntervalSince(first.timestamp)
        guard timeDiff > 0 else { return nil }

        let bytesDiff = first.freeBytes - last.freeBytes // positiivinen = tila vähenee
        let bytesPerHour = Double(bytesDiff) / (timeDiff / 3600)

        // Arvio milloin täynnä
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

    /// Päivitä trenditiedot
    func refreshTrend(for mountPoint: String) {
        trend = calculateTrend(for: mountPoint)
        recentSnapshots = getSnapshots(for: mountPoint, hours: 24)
    }

    /// Siivoa vanhat snapshotit (yli 7 päivää)
    func cleanupOldSnapshots() {
        guard let context = modelContext else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

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
            print("🧹 Siivottu \(oldSnapshots.count) vanhaa snapshotia")
        } catch {
            print("❌ Siivous virhe: \(error)")
        }
    }
}

/// Trenditiedot
struct TrendInfo {
    let bytesPerHour: Int64
    let bytesPerDay: Int64
    let daysUntilFull: Double?
    let dataPoints: Int
    let periodHours: Int

    var isIncreasing: Bool { bytesPerDay < 0 } // negatiivinen = tila kasvaa (hyvä)
    var isDecreasing: Bool { bytesPerDay > 0 } // positiivinen = tila vähenee (huono)

    var trendDescription: String {
        if bytesPerDay == 0 {
            return "Vakaa"
        } else if bytesPerDay > 0 {
            return "−\(bytesPerDay.formattedBytes)/päivä"
        } else {
            return "+\(abs(bytesPerDay).formattedBytes)/päivä"
        }
    }

    var fullWarning: String? {
        guard let days = daysUntilFull, days > 0 && days < 30 else { return nil }

        if days < 1 {
            return "⚠️ Levy täynnä alle 24 tunnissa!"
        } else if days < 7 {
            return "⚠️ Levy täynnä noin \(Int(days)) päivässä"
        } else {
            return "Levy täynnä noin \(Int(days)) päivässä"
        }
    }
}
