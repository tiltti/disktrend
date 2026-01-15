import Foundation
import Darwin

// MARK: - CPU Monitor

@MainActor
final class CPUMonitor: ObservableObject {
    @Published var usage: Double = 0  // 0-100%
    @Published var userUsage: Double = 0
    @Published var systemUsage: Double = 0
    @Published var idleUsage: Double = 0
    @Published var coreCount: Int = 0
    @Published var lastUpdate: Date = Date()

    private var previousTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    private var timer: Timer?

    init() {
        coreCount = ProcessInfo.processInfo.processorCount
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
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(
                    mach_host_self(),
                    HOST_CPU_LOAD_INFO,
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            print("[CPUMonitor] Failed to get CPU stats: \(result)")
            return
        }

        let currentTicks = (
            user: cpuInfo.cpu_ticks.0,
            system: cpuInfo.cpu_ticks.1,
            idle: cpuInfo.cpu_ticks.2,
            nice: cpuInfo.cpu_ticks.3
        )

        if let prev = previousTicks {
            let userDiff = Double(currentTicks.user &- prev.user)
            let systemDiff = Double(currentTicks.system &- prev.system)
            let idleDiff = Double(currentTicks.idle &- prev.idle)
            let niceDiff = Double(currentTicks.nice &- prev.nice)

            let totalDiff = userDiff + systemDiff + idleDiff + niceDiff

            if totalDiff > 0 {
                userUsage = (userDiff + niceDiff) / totalDiff * 100
                systemUsage = systemDiff / totalDiff * 100
                idleUsage = idleDiff / totalDiff * 100
                usage = userUsage + systemUsage
            }
        }

        previousTicks = currentTicks
        lastUpdate = Date()
    }
}

// MARK: - CPU Info Struct

struct CPUInfo {
    let usage: Double
    let userUsage: Double
    let systemUsage: Double
    let coreCount: Int

    var formattedUsage: String {
        String(format: "%.0f%%", usage)
    }
}
