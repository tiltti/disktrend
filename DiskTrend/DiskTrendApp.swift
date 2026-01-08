import SwiftUI

@main
struct DiskTrendApp: App {
    @StateObject private var diskMonitor = DiskMonitor()
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    init() {
        print("[DiskTrend] Starting...")
    }

    private var colorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceMode)?.colorScheme
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(diskMonitor: diskMonitor)
                .preferredColorScheme(colorScheme)
        } label: {
            MenuBarView(diskMonitor: diskMonitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(diskMonitor: diskMonitor)
                .preferredColorScheme(colorScheme)
        }
    }
}
