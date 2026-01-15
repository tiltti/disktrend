import AppKit
import SwiftUI

// MARK: - Settings Window Controller

/// Custom settings window controller because MenuBarExtra + Settings scene doesn't work well
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show(moduleManager: ModuleManager) {
        // Close all popovers/menu bar windows
        for window in NSApp.windows where window.className.contains("MenuBarExtra") || window.level == .popUpMenu {
            window.close()
        }

        if let window = window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(moduleManager: moduleManager)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = String(localized: "settings.title")
        newWindow.styleMask = [.titled, .closable]
        newWindow.level = .floating
        newWindow.center()
        newWindow.setFrameAutosaveName("BarBarSettingsWindow")

        self.window = newWindow

        // Small delay to allow popover to close
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            newWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
