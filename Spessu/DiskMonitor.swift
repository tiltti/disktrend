import Foundation
import Combine

struct VolumeInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let mountPoint: String
    let totalBytes: Int64
    let freeBytes: Int64
    let isRemovable: Bool
    let isInternal: Bool

    var usedBytes: Int64 { totalBytes - freeBytes }
    var usedPercentage: Double { Double(usedBytes) / Double(totalBytes) * 100 }
    var freePercentage: Double { Double(freeBytes) / Double(totalBytes) * 100 }

    var status: DiskStatus {
        let freePercent = freePercentage
        if freePercent < 5 { return .critical }
        if freePercent < 10 { return .warning }
        if freePercent < 20 { return .caution }
        return .healthy
    }

    static func == (lhs: VolumeInfo, rhs: VolumeInfo) -> Bool {
        lhs.mountPoint == rhs.mountPoint &&
        lhs.totalBytes == rhs.totalBytes &&
        lhs.freeBytes == rhs.freeBytes
    }
}

enum DiskStatus {
    case healthy   // > 20% free - vihreä
    case caution   // 10-20% free - keltainen
    case warning   // 5-10% free - oranssi
    case critical  // < 5% free - punainen

    var color: String {
        switch self {
        case .healthy: return "green"
        case .caution: return "yellow"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

@MainActor
class DiskMonitor: ObservableObject {
    @Published var volumes: [VolumeInfo] = []
    @Published var primaryVolume: VolumeInfo?
    @Published var lastUpdate: Date = Date()
    @Published var trend: TrendInfo?

    private var timer: Timer?
    private var snapshotTimer: Timer?
    private var updateInterval: TimeInterval = 30 // sekuntia
    private var snapshotInterval: TimeInterval = 300 // 5 minuuttia

    var historyManager: DiskHistoryManager?

    init() {
        refresh()
        startMonitoring()
        // Historia alustetaan viiveellä
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                self.historyManager = DiskHistoryManager()
                self.saveSnapshot()
            }
        }
    }

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        // Snapshot-ajastin (5 min välein)
        snapshotTimer?.invalidate()
        snapshotTimer = Timer.scheduledTimer(withTimeInterval: snapshotInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveSnapshot()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        snapshotTimer?.invalidate()
        snapshotTimer = nil
    }

    func refresh() {
        volumes = getAllVolumes()
        primaryVolume = volumes.first { $0.mountPoint == "/" }
        lastUpdate = Date()
        refreshTrend()
    }

    func saveSnapshot() {
        historyManager?.saveSnapshots(volumes: volumes)
        historyManager?.cleanupOldSnapshots()
    }

    func refreshTrend() {
        guard let primary = primaryVolume, let history = historyManager else { return }
        history.refreshTrend(for: primary.mountPoint)
        trend = history.trend
    }

    private func getAllVolumes() -> [VolumeInfo] {
        let fileManager = FileManager.default
        var result: [VolumeInfo] = []

        // Hae kaikki mountatut volyymit
        guard let mountedVolumeURLs = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeIsRemovableKey,
                .volumeIsInternalKey
            ],
            options: [.skipHiddenVolumes]
        ) else {
            return result
        }

        for volumeURL in mountedVolumeURLs {
            do {
                let resourceValues = try volumeURL.resourceValues(forKeys: [
                    .volumeNameKey,
                    .volumeTotalCapacityKey,
                    .volumeAvailableCapacityKey,
                    .volumeIsRemovableKey,
                    .volumeIsInternalKey
                ])

                guard let name = resourceValues.volumeName,
                      let totalCapacity = resourceValues.volumeTotalCapacity,
                      let availableCapacity = resourceValues.volumeAvailableCapacity else {
                    continue
                }

                let volumeInfo = VolumeInfo(
                    name: name,
                    mountPoint: volumeURL.path,
                    totalBytes: Int64(totalCapacity),
                    freeBytes: Int64(availableCapacity),
                    isRemovable: resourceValues.volumeIsRemovable ?? false,
                    isInternal: resourceValues.volumeIsInternal ?? true
                )

                result.append(volumeInfo)
            } catch {
                print("Virhe volyymin tietojen haussa: \(error)")
            }
        }

        // Järjestä: päälevy ensin, sitten sisäiset, sitten ulkoiset
        return result.sorted { lhs, rhs in
            if lhs.mountPoint == "/" { return true }
            if rhs.mountPoint == "/" { return false }
            if lhs.isInternal != rhs.isInternal { return lhs.isInternal }
            return lhs.name < rhs.name
        }
    }
}

// MARK: - Formatointi
extension Int64 {
    var formattedBytes: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: self)
    }

    var formattedBytesShort: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        formatter.zeroPadsFractionDigits = false
        return formatter.string(fromByteCount: self)
    }
}
