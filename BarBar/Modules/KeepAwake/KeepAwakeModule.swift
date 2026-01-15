import SwiftUI

// MARK: - Keep-Awake Module

@MainActor
final class KeepAwakeModule: BarBarModule, ObservableObject {
    // MARK: - Module Identity

    static let moduleId = "keep-awake"
    static let moduleName = String(localized: "module.keepAwake.name")
    static let moduleIcon = "cup.and.saucer.fill"
    static let moduleDescription = String(localized: "module.keepAwake.description")

    // MARK: - Settings

    @AppStorage("keepAwake.enabled") var isEnabled: Bool = true
    @AppStorage("keepAwake.defaultMode") private var defaultModeRaw: String = PowerManager.AwakeMode.preventDisplaySleep.rawValue
    @AppStorage("keepAwake.defaultDuration") private var defaultDurationId: String = "indefinite"

    // MARK: - State

    @Published var powerManager = PowerManager()

    var isActive: Bool { powerManager.isActive }

    var defaultMode: PowerManager.AwakeMode {
        get { PowerManager.AwakeMode(rawValue: defaultModeRaw) ?? .preventDisplaySleep }
        set { defaultModeRaw = newValue.rawValue }
    }

    var defaultDuration: PowerManager.Duration {
        get { PowerManager.Duration.allCases.first { $0.id == defaultDurationId } ?? .indefinite }
        set { defaultDurationId = newValue.id }
    }

    // MARK: - Status

    var statusSummary: String {
        if powerManager.isActive {
            if let remaining = powerManager.remainingTimeFormatted {
                return "\(remaining)"
            }
            return String(localized: "keepAwake.active")
        }
        return String(localized: "keepAwake.inactive")
    }

    // MARK: - Lifecycle

    func onActivate() {
        // Nothing to do on module activation
    }

    func onDeactivate() {
        powerManager.deactivate()
    }

    func onAppWillTerminate() {
        powerManager.deactivate()
    }

    // MARK: - Actions

    func quickToggle() {
        powerManager.toggle(mode: defaultMode, duration: defaultDuration.seconds)
    }

    func activate(mode: PowerManager.AwakeMode, duration: PowerManager.Duration) {
        powerManager.activate(mode: mode, duration: duration.seconds)
    }

    // MARK: - Views

    func makeContentView() -> some View {
        KeepAwakeView(module: self)
    }

    func makeSettingsView() -> some View {
        KeepAwakeSettingsView(module: self)
    }

    func makeStatusView() -> some View {
        KeepAwakeStatusView(module: self)
    }
}
