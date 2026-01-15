import SwiftUI
import ServiceManagement

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var moduleManager: ModuleManager

    var body: some View {
        TabView {
            // General settings
            GeneralSettingsView()
                .tabItem {
                    Label(String(localized: "settings.general"), systemImage: "gear")
                }

            // Module-specific settings
            ForEach(moduleManager.modules) { module in
                module.settingsView
                    .tabItem {
                        Label(module.name, systemImage: module.icon)
                    }
            }

            // About
            AboutView()
                .tabItem {
                    Label(String(localized: "settings.about"), systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 380)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("menuBar.displayMode") private var displayMode: Int = 0
    @State private var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appearanceMode) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }

                Picker("Menu Bar Display", selection: $displayMode) {
                    ForEach(MenuBarDisplayMode.allCases, id: \.rawValue) { mode in
                        Label(mode.name, systemImage: mode.icon).tag(mode.rawValue)
                    }
                }
            } header: {
                Text("Appearance")
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            } header: {
                Text("Startup")
            }

            Section {
                ModuleToggleList()
            } header: {
                Text("Modules")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[Settings] Launch at login error: \(error)")
        }
    }
}

// MARK: - Module Toggle List

struct ModuleToggleList: View {
    @ObservedObject var moduleManager = ModuleManager.shared

    var body: some View {
        ForEach(moduleManager.modules) { module in
            Toggle(isOn: Binding(
                get: { module.isEnabled },
                set: { newValue in
                    module.isEnabled = newValue
                    if newValue {
                        module.activate()
                    } else {
                        module.deactivate()
                    }
                }
            )) {
                Label(module.name, systemImage: module.icon)
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "menubar.dock.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("BarBar")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .foregroundColor(.secondary)

            Text("A collection of useful menu bar tools for your Mac.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()

            Text("Made with Swift & SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
    }
}
