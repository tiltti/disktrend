import SwiftUI
import Combine

/// Manages all BarBar modules
@MainActor
final class ModuleManager: ObservableObject {
    static let shared = ModuleManager()

    /// All registered modules (type-erased)
    @Published private(set) var modules: [AnyModule] = []

    /// Currently selected module ID for the popover
    @Published var activeModuleId: String?

    /// Internal storage for actual module instances
    private var systemMonitor: SystemMonitorModule?
    private var keepAwake: KeepAwakeModule?
    private var menuBarOrganizer: MenuBarOrganizerModule?

    private init() {
        registerBuiltInModules()
    }

    private func registerBuiltInModules() {
        // Create module instances
        let sysMonitor = SystemMonitorModule()
        let keepAwakeModule = KeepAwakeModule()
        let menuBarOrgModule = MenuBarOrganizerModule()

        // Store references
        self.systemMonitor = sysMonitor
        self.keepAwake = keepAwakeModule
        self.menuBarOrganizer = menuBarOrgModule

        // Create type-erased wrappers
        modules = [
            AnyModule(sysMonitor),
            AnyModule(keepAwakeModule),
            AnyModule(menuBarOrgModule)
        ]

        // Set default active module
        activeModuleId = SystemMonitorModule.moduleId
    }

    /// Get enabled modules only
    var enabledModules: [AnyModule] {
        modules.filter { $0.isEnabled }
    }

    /// Activate all enabled modules
    func activateAll() {
        for module in modules where module.isEnabled {
            module.activate()
        }
    }

    /// Deactivate all modules
    func deactivateAll() {
        for module in modules {
            module.deactivate()
        }
    }

    /// Get a specific module by type
    func getSystemMonitor() -> SystemMonitorModule? {
        systemMonitor
    }

    func getKeepAwake() -> KeepAwakeModule? {
        keepAwake
    }

    func getMenuBarOrganizer() -> MenuBarOrganizerModule? {
        menuBarOrganizer
    }

    /// Get the primary status summary for menu bar display
    var primaryStatusSummary: String {
        // Priority: Keep-Awake if active, otherwise System Monitor
        if let keepAwake = keepAwake, keepAwake.isActive {
            return keepAwake.statusSummary
        }
        if let sysMonitor = systemMonitor, sysMonitor.isEnabled {
            return sysMonitor.statusSummary
        }
        return ""
    }

    /// Check if Keep-Awake is currently active
    var isKeepAwakeActive: Bool {
        keepAwake?.isActive ?? false
    }
}
