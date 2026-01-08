import SwiftUI

@main
struct SpessuApp: App {
    @StateObject private var diskMonitor = DiskMonitor()

    init() {
        print("[Spessu] Starting...")
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
