import SwiftUI

@main
struct DiskTrendApp: App {
    @StateObject private var diskMonitor = DiskMonitor()

    init() {
        print("[DiskTrend] Starting...")
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(diskMonitor: diskMonitor)
        } label: {
            MenuBarView(diskMonitor: diskMonitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(diskMonitor: diskMonitor)
        }
    }
}
