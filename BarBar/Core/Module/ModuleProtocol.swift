import SwiftUI

// MARK: - Module Protocol

/// Base protocol for all BarBar modules
@MainActor
protocol BarBarModule: AnyObject, ObservableObject, Identifiable {
    /// Unique identifier for the module
    static var moduleId: String { get }

    /// Localized display name
    static var moduleName: String { get }

    /// SF Symbol name for the module icon
    static var moduleIcon: String { get }

    /// Localized description
    static var moduleDescription: String { get }

    /// Whether the module is enabled
    var isEnabled: Bool { get set }

    /// Short status summary for display in menu bar or header
    var statusSummary: String { get }

    /// Called when module is activated
    func onActivate()

    /// Called when module is deactivated
    func onDeactivate()

    /// Called when app is about to terminate
    func onAppWillTerminate()

    /// The main content view for the module
    associatedtype ContentView: View
    @ViewBuilder func makeContentView() -> ContentView

    /// The settings view for the module
    associatedtype SettingsContentView: View
    @ViewBuilder func makeSettingsView() -> SettingsContentView

    /// Compact status view for the header
    associatedtype StatusView: View
    @ViewBuilder func makeStatusView() -> StatusView
}

// MARK: - Default Implementations

extension BarBarModule {
    var id: String { Self.moduleId }

    func onAppWillTerminate() {
        onDeactivate()
    }
}

// MARK: - Type-Erased Module Wrapper

/// Type-erased wrapper for modules to use in SwiftUI collections
@MainActor
struct AnyModule: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String

    private let _isEnabled: @MainActor () -> Bool
    private let _setEnabled: @MainActor (Bool) -> Void
    private let _statusSummary: @MainActor () -> String
    private let _contentView: @MainActor () -> AnyView
    private let _settingsView: @MainActor () -> AnyView
    private let _statusView: @MainActor () -> AnyView
    private let _onActivate: @MainActor () -> Void
    private let _onDeactivate: @MainActor () -> Void

    init<M: BarBarModule>(_ module: M) {
        self.id = M.moduleId
        self.name = M.moduleName
        self.icon = M.moduleIcon
        self.description = M.moduleDescription

        self._isEnabled = { module.isEnabled }
        self._setEnabled = { module.isEnabled = $0 }
        self._statusSummary = { module.statusSummary }
        self._contentView = { AnyView(module.makeContentView()) }
        self._settingsView = { AnyView(module.makeSettingsView()) }
        self._statusView = { AnyView(module.makeStatusView()) }
        self._onActivate = { module.onActivate() }
        self._onDeactivate = { module.onDeactivate() }
    }

    var isEnabled: Bool {
        get { _isEnabled() }
        nonmutating set { _setEnabled(newValue) }
    }

    var statusSummary: String { _statusSummary() }
    var contentView: AnyView { _contentView() }
    var settingsView: AnyView { _settingsView() }
    var statusView: AnyView { _statusView() }

    func activate() { _onActivate() }
    func deactivate() { _onDeactivate() }
}
