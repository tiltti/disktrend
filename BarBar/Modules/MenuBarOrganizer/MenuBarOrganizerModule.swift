import SwiftUI

@MainActor
final class MenuBarOrganizerModule: BarBarModule, ObservableObject {

    // MARK: - Module Identity

    static let moduleId = "menubar-organizer"
    static let moduleName = String(localized: "module.menuBarOrganizer.name")
    static let moduleIcon = "menubar.rectangle"
    static let moduleDescription = String(localized: "module.menuBarOrganizer.description")

    // MARK: - Settings

    @AppStorage("menuBarOrganizer.enabled") var isEnabled: Bool = true

    // MARK: - State

    let menuBarHider = MenuBarHider()
    @Published private(set) var isHidingIcons: Bool = false

    var statusSummary: String {
        isHidingIcons
            ? String(localized: "menuBarOrganizer.collapsed")
            : String(localized: "menuBarOrganizer.expanded")
    }

    // MARK: - Init

    init() {
        menuBarHider.onStateChanged = { [weak self] in
            self?.isHidingIcons = self?.menuBarHider.isHidden ?? false
        }
    }

    // MARK: - Lifecycle

    func onActivate() {
        menuBarHider.loadSettings()
        isHidingIcons = menuBarHider.isHidden
    }

    func onDeactivate() {
        menuBarHider.cleanup()
    }

    func onAppWillTerminate() {
        menuBarHider.cleanup()
    }

    // MARK: - Actions

    func toggle() {
        menuBarHider.toggleVisibility()
    }

    func showAllIcons() {
        menuBarHider.expand()
    }

    func hideIcons() {
        menuBarHider.collapse()
    }

    // MARK: - Views

    func makeContentView() -> some View {
        MenuBarOrganizerView(module: self)
    }

    func makeSettingsView() -> some View {
        MenuBarOrganizerSettingsView(module: self)
    }

    func makeStatusView() -> some View {
        MenuBarOrganizerStatusView(module: self)
    }
}
