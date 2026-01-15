import Foundation
import IOKit.pwr_mgt

// MARK: - Power Manager

@MainActor
final class PowerManager: ObservableObject {
    @Published private(set) var isActive: Bool = false
    @Published private(set) var activeMode: AwakeMode = .preventDisplaySleep
    @Published private(set) var activeSince: Date?
    @Published private(set) var scheduledEnd: Date?

    private var assertionID: IOPMAssertionID = 0
    private var deactivationTask: Task<Void, Never>?

    // MARK: - Awake Modes

    enum AwakeMode: String, CaseIterable, Identifiable {
        case preventDisplaySleep = "PreventUserIdleDisplaySleep"
        case preventSystemSleep = "PreventUserIdleSystemSleep"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .preventDisplaySleep:
                return String(localized: "keepAwake.mode.display")
            case .preventSystemSleep:
                return String(localized: "keepAwake.mode.system")
            }
        }

        var description: String {
            switch self {
            case .preventDisplaySleep:
                return String(localized: "keepAwake.mode.display.description")
            case .preventSystemSleep:
                return String(localized: "keepAwake.mode.system.description")
            }
        }

        var icon: String {
            switch self {
            case .preventDisplaySleep:
                return "display"
            case .preventSystemSleep:
                return "powersleep"
            }
        }
    }

    // MARK: - Duration Presets

    enum Duration: CaseIterable, Identifiable {
        case minutes15
        case minutes30
        case hour1
        case hours2
        case hours4
        case indefinite

        var id: String {
            switch self {
            case .minutes15: return "15min"
            case .minutes30: return "30min"
            case .hour1: return "1h"
            case .hours2: return "2h"
            case .hours4: return "4h"
            case .indefinite: return "indefinite"
            }
        }

        var seconds: TimeInterval? {
            switch self {
            case .minutes15: return 15 * 60
            case .minutes30: return 30 * 60
            case .hour1: return 60 * 60
            case .hours2: return 2 * 60 * 60
            case .hours4: return 4 * 60 * 60
            case .indefinite: return nil
            }
        }

        var displayName: String {
            switch self {
            case .minutes15: return "15 min"
            case .minutes30: return "30 min"
            case .hour1: return "1 hour"
            case .hours2: return "2 hours"
            case .hours4: return "4 hours"
            case .indefinite: return String(localized: "keepAwake.indefinite")
            }
        }
    }

    // MARK: - Activation

    func activate(mode: AwakeMode = .preventDisplaySleep, duration: TimeInterval? = nil) {
        // Deactivate first if already active
        if isActive {
            deactivate()
        }

        let reason = "BarBar Keep-Awake" as CFString
        let type = mode.rawValue as CFString

        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )

        if result == kIOReturnSuccess {
            isActive = true
            activeMode = mode
            activeSince = Date()

            // Schedule deactivation if duration specified
            if let duration = duration {
                scheduledEnd = Date().addingTimeInterval(duration)
                scheduleDeactivation(after: duration)
            } else {
                scheduledEnd = nil
            }

            print("[PowerManager] Activated: \(mode.rawValue)")
        } else {
            print("[PowerManager] Activation failed: \(result)")
        }
    }

    func deactivate() {
        guard isActive else { return }

        // Cancel any scheduled deactivation
        deactivationTask?.cancel()
        deactivationTask = nil

        let result = IOPMAssertionRelease(assertionID)

        if result == kIOReturnSuccess {
            isActive = false
            activeSince = nil
            scheduledEnd = nil
            assertionID = 0
            print("[PowerManager] Deactivated")
        } else {
            print("[PowerManager] Deactivation failed: \(result)")
        }
    }

    func toggle(mode: AwakeMode = .preventDisplaySleep, duration: TimeInterval? = nil) {
        if isActive {
            deactivate()
        } else {
            activate(mode: mode, duration: duration)
        }
    }

    private func scheduleDeactivation(after seconds: TimeInterval) {
        deactivationTask?.cancel()

        deactivationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if !Task.isCancelled {
                self.deactivate()
            }
        }
    }

    // MARK: - Status

    var remainingTime: TimeInterval? {
        guard let end = scheduledEnd else { return nil }
        let remaining = end.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    var remainingTimeFormatted: String? {
        guard let remaining = remainingTime else { return nil }
        let minutes = Int(remaining / 60)
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var activeDuration: TimeInterval? {
        guard let since = activeSince else { return nil }
        return Date().timeIntervalSince(since)
    }

    var activeDurationFormatted: String? {
        guard let duration = activeDuration else { return nil }
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, mins)
        } else {
            return String(format: "%dm", mins)
        }
    }
}
