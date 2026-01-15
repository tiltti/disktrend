import SwiftUI
import AppKit

@main
struct BarBarApp: App {
    @StateObject private var moduleManager = ModuleManager.shared
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    init() {
        print("[BarBar] Starting...")
    }

    var body: some Scene {
        MenuBarExtra {
            MainPopoverView(moduleManager: moduleManager)
                .onAppear {
                    applyAppearance(appearanceMode)
                    moduleManager.activateAll()
                }
                .onChange(of: appearanceMode) { _, newValue in
                    applyAppearance(newValue)
                }
        } label: {
            MenuBarView(moduleManager: moduleManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(moduleManager: moduleManager)
        }
    }
}

// MARK: - Appearance

enum AppearanceMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var name: String {
        switch self {
        case .system: return String(localized: "appearance.system")
        case .light: return String(localized: "appearance.light")
        case .dark: return String(localized: "appearance.dark")
        }
    }
}

private func applyAppearance(_ mode: Int) {
    let appearanceMode = AppearanceMode(rawValue: mode) ?? .system
    switch appearanceMode {
    case .system:
        NSApp.appearance = nil
    case .light:
        NSApp.appearance = NSAppearance(named: .aqua)
    case .dark:
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
}
