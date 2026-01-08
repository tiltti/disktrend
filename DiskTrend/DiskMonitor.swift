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

    func status(warningThreshold: Double = 10, criticalThreshold: Double = 5) -> DiskStatus {
        let freePercent = freePercentage
        if freePercent < criticalThreshold { return .critical }
        if freePercent < warningThreshold { return .warning }
        if freePercent < warningThreshold + 10 { return .caution }
        return .healthy
    }

    // Default status for legacy calls
    var status: DiskStatus {
        let warning = UserDefaults.standard.double(forKey: "warningThreshold")
        let critical = UserDefaults.standard.double(forKey: "criticalThreshold")
        return status(
            warningThreshold: warning > 0 ? warning : 10,
            criticalThreshold: critical > 0 ? critical : 5
        )
    }

    static func == (lhs: VolumeInfo, rhs: VolumeInfo) -> Bool {
        lhs.mountPoint == rhs.mountPoint &&
        lhs.totalBytes == rhs.totalBytes &&
        lhs.freeBytes == rhs.freeBytes
    }
}

enum DiskStatus {
    case healthy   // > 20% free - green
    case caution   // 10-20% free - yellow
    case warning   // 5-10% free - orange
    case critical  // < 5% free - red

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
    @Published var displayMode: MenuBarDisplayMode = .iconAndText

    private var timer: Timer?
    private var snapshotTimer: Timer?
    private var snapshotInterval: TimeInterval = 300 // 5 minutes

    var updateInterval: TimeInterval {
        let interval = UserDefaults.standard.double(forKey: "updateInterval")
        return interval > 0 ? interval : 30
    }

    var historyManager: DiskHistoryManager?

    init() {
        let modeRaw = UserDefaults.standard.integer(forKey: "displayMode")
        displayMode = MenuBarDisplayMode(rawValue: modeRaw) ?? .iconAndText
        // Load data synchronously immediately
        volumes = getAllVolumes()
        primaryVolume = volumes.first { $0.mountPoint == "/" }
        lastUpdate = Date()
        startMonitoring()
        // Initialize history in background (no UI delay)
        Task.detached(priority: .background) {
            let manager = await DiskHistoryManager()
            await MainActor.run {
                self.historyManager = manager
                self.saveSnapshot()
                self.refreshTrend()
            }
        }
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSettingsChange()
            }
        }
    }

    private func handleSettingsChange() {
        let modeRaw = UserDefaults.standard.integer(forKey: "displayMode")
        displayMode = MenuBarDisplayMode(rawValue: modeRaw) ?? .iconAndText
        // Restart timer with new interval
        startMonitoring()
    }

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        // Snapshot timer (every 5 min)
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

        // Get all mounted volumes
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
                print("[DiskMonitor] Error fetching volume info: \(error)")
            }
        }

        // Sort: primary disk first, then internal, then external
        return result.sorted { lhs, rhs in
            if lhs.mountPoint == "/" { return true }
            if rhs.mountPoint == "/" { return false }
            if lhs.isInternal != rhs.isInternal { return lhs.isInternal }
            return lhs.name < rhs.name
        }
    }
}

// MARK: - Formatting
extension Int64 {
    var formattedBytes: String {
        formattedBytes(decimals: nil)
    }

    var formattedBytesShort: String {
        let decimals = UserDefaults.standard.integer(forKey: "decimalPlaces")
        return formattedBytes(decimals: decimals)
    }

    func formattedBytes(decimals: Int?) -> String {
        let bytes = Double(self)
        let gb = bytes / 1_000_000_000
        let tb = bytes / 1_000_000_000_000

        let decimalPlaces = decimals ?? 1

        if tb >= 1 {
            return String(format: "%.\(decimalPlaces)f TB", tb)
        } else {
            return String(format: "%.\(decimalPlaces)f GB", gb)
        }
    }
}
