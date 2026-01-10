import SwiftUI
import AppKit

@main
struct DiskTrendApp: App {
    @StateObject private var diskMonitor = DiskMonitor()
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    init() {
        print("[DiskTrend] Starting...")
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(diskMonitor: diskMonitor)
                .onAppear {
                    applyAppearance(appearanceMode)
                }
                .onChange(of: appearanceMode) { _, newValue in
                    applyAppearance(newValue)
                }
        } label: {
            MenuBarView(diskMonitor: diskMonitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(diskMonitor: diskMonitor)
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
