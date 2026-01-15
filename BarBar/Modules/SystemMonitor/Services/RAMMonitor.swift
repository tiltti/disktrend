import Foundation
import Darwin

// MARK: - RAM Monitor

@MainActor
final class RAMMonitor: ObservableObject {
    @Published var totalBytes: UInt64 = 0
    @Published var usedBytes: UInt64 = 0
    @Published var freeBytes: UInt64 = 0
    @Published var activeBytes: UInt64 = 0
    @Published var wiredBytes: UInt64 = 0
    @Published var compressedBytes: UInt64 = 0
    @Published var lastUpdate: Date = Date()

    private var timer: Timer?

    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }

    var freePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(freeBytes) / Double(totalBytes) * 100
    }

    init() {
        totalBytes = ProcessInfo.processInfo.physicalMemory
        refresh()
    }

    func startMonitoring(interval: TimeInterval = 2.0) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            print("[RAMMonitor] Failed to get memory stats: \(result)")
            return
        }

        let pageSize = UInt64(vm_page_size)

        activeBytes = UInt64(stats.active_count) * pageSize
        wiredBytes = UInt64(stats.wire_count) * pageSize
        compressedBytes = UInt64(stats.compressor_page_count) * pageSize
        freeBytes = UInt64(stats.free_count) * pageSize

        // "Used" = Active + Wired + Compressed (like Activity Monitor)
        usedBytes = activeBytes + wiredBytes + compressedBytes

        lastUpdate = Date()
    }
}

// MARK: - RAM Info Struct

struct RAMInfo {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let freeBytes: UInt64
    let usedPercentage: Double

    var formattedTotal: String {
        ByteFormatter.format(Int64(totalBytes))
    }

    var formattedUsed: String {
        ByteFormatter.format(Int64(usedBytes))
    }

    var formattedFree: String {
        ByteFormatter.format(Int64(freeBytes))
    }

    var formattedPercentage: String {
        String(format: "%.0f%%", usedPercentage)
    }
}

// MARK: - Byte Formatter

enum ByteFormatter {
    static func format(_ bytes: Int64, decimals: Int = 1) -> String {
        let absBytes = Double(abs(bytes))
        let gb = absBytes / 1_000_000_000
        let tb = absBytes / 1_000_000_000_000

        if tb >= 1 {
            return String(format: "%.\(decimals)f TB", tb)
        } else {
            return String(format: "%.\(decimals)f GB", gb)
        }
    }

    static func formatShort(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_000_000_000
        return String(format: "%.1f GB", gb)
    }
}
