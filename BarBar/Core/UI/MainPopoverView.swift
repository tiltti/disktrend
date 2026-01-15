import SwiftUI

// MARK: - Main Popover View

struct MainPopoverView: View {
    @ObservedObject var moduleManager: ModuleManager
    @State private var selectedModuleId: String?

    private var enabledModules: [AnyModule] {
        moduleManager.enabledModules
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(moduleManager: moduleManager)

            Divider()

            // Module content
            if enabledModules.count > 1 {
                // Tab view for multiple modules
                TabView(selection: $selectedModuleId) {
                    ForEach(enabledModules) { module in
                        module.contentView
                            .tag(module.id as String?)
                            .tabItem {
                                Label(module.name, systemImage: module.icon)
                            }
                    }
                }
                .tabViewStyle(.automatic)
            } else if let module = enabledModules.first {
                // Single module
                module.contentView
            } else {
                // No modules enabled
                EmptyStateView()
            }

            Divider()

            // Footer
            FooterView(moduleManager: moduleManager)
        }
        .frame(width: 380, height: 500)
        .onAppear {
            selectedModuleId = moduleManager.activeModuleId ?? enabledModules.first?.id
        }
    }
}

// MARK: - Header View

private struct HeaderView: View {
    @ObservedObject var moduleManager: ModuleManager

    var body: some View {
        HStack {
            // App name
            HStack(spacing: 6) {
                Image(systemName: "menubar.dock.rectangle")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text("BarBar")
                    .font(.headline)
            }

            Spacer()

            // Quick status indicators
            HStack(spacing: 8) {
                ForEach(moduleManager.enabledModules.prefix(3)) { module in
                    module.statusView
                }
            }
        }
        .padding()
    }
}

// MARK: - Footer View

private struct FooterView: View {
    @ObservedObject var moduleManager: ModuleManager

    var body: some View {
        HStack {
            Button(action: openSettings) {
                Label(String(localized: "action.settings"), systemImage: "gear")
            }

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label(String(localized: "action.quit"), systemImage: "power")
            }
        }
        .buttonStyle(.borderless)
        .padding()
    }

    private func openSettings() {
        SettingsWindowController.shared.show(moduleManager: moduleManager)
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No modules enabled")
                .font(.headline)

            Text("Enable modules in Settings to see them here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
