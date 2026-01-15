import SwiftUI

struct MenuBarOrganizerView: View {
    @ObservedObject var module: MenuBarOrganizerModule

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "menubar.rectangle")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Menu Bar Organizer")
                        .font(.headline)
                    Text(module.isHidingIcons ? "Icons hidden" : "Icons visible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { module.toggle() }) {
                    Image(systemName: module.isHidingIcons ? "eye" : "eye.slash")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .tint(module.isHidingIcons ? .blue : .secondary)
            }

            Divider()

            // Quick actions
            HStack(spacing: 12) {
                Button(action: { module.showAllIcons() }) {
                    VStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.title2)
                        Text("Show All")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(!module.isHidingIcons ? .blue : .secondary)

                Button(action: { module.hideIcons() }) {
                    VStack(spacing: 6) {
                        Image(systemName: "eye.slash")
                            .font(.title2)
                        Text("Hide")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(module.isHidingIcons ? .blue : .secondary)
            }

            Divider()

            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("How to use")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                    Text("Hold ⌘ and drag ••• to position it")
                        .font(.caption)
                }

                HStack(spacing: 8) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                    Text("Click ••• to hide icons to its left")
                        .font(.caption)
                }

                HStack(spacing: 8) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.blue)
                    Text("Click ‹‹ to show them again")
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct MenuBarOrganizerSettingsView: View {
    @ObservedObject var module: MenuBarOrganizerModule

    var body: some View {
        Form {
            Section {
                Text("The ••• icon in your menu bar controls which icons are visible.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Hold ⌘ and drag it to set the dividing point between visible and hidden icons.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("How It Works")
            }
        }
        .formStyle(.grouped)
    }
}

struct MenuBarOrganizerStatusView: View {
    @ObservedObject var module: MenuBarOrganizerModule

    var body: some View {
        if module.isHidingIcons {
            Image(systemName: "eye.slash")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
}
