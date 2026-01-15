import SwiftUI

// MARK: - Keep-Awake View

struct KeepAwakeView: View {
    @ObservedObject var module: KeepAwakeModule
    @State private var selectedMode: PowerManager.AwakeMode = .preventDisplaySleep
    @State private var selectedDuration: PowerManager.Duration = .indefinite

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status Header
            StatusHeader(module: module)

            Divider()

            // Mode Selection
            ModeSection(selectedMode: $selectedMode, isActive: module.isActive)

            // Duration Presets
            DurationSection(
                selectedDuration: $selectedDuration,
                module: module,
                selectedMode: selectedMode
            )

            // Remaining Time
            if let end = module.powerManager.scheduledEnd {
                RemainingTimeView(endTime: end)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            selectedMode = module.defaultMode
            selectedDuration = module.defaultDuration
        }
    }
}

// MARK: - Status Header

private struct StatusHeader: View {
    @ObservedObject var module: KeepAwakeModule

    var body: some View {
        HStack {
            Image(systemName: module.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                .font(.title)
                .foregroundColor(module.isActive ? .orange : .secondary)
                .symbolEffect(.bounce, value: module.isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(module.isActive ?
                     String(localized: "keepAwake.status.active") :
                     String(localized: "keepAwake.status.inactive"))
                    .font(.headline)

                if let since = module.powerManager.activeSince {
                    Text("Since \(since.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Main Toggle
            Toggle("", isOn: Binding(
                get: { module.isActive },
                set: { newValue in
                    if newValue {
                        module.quickToggle()
                    } else {
                        module.powerManager.deactivate()
                    }
                }
            ))
            .toggleStyle(.switch)
            .tint(.orange)
        }
    }
}

// MARK: - Mode Section

private struct ModeSection: View {
    @Binding var selectedMode: PowerManager.AwakeMode
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker("", selection: $selectedMode) {
                ForEach(PowerManager.AwakeMode.allCases) { mode in
                    HStack {
                        Image(systemName: mode.icon)
                        Text(mode.displayName)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isActive)

            Text(selectedMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Duration Section

private struct DurationSection: View {
    @Binding var selectedDuration: PowerManager.Duration
    @ObservedObject var module: KeepAwakeModule
    let selectedMode: PowerManager.AwakeMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Duration buttons in a grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(PowerManager.Duration.allCases) { duration in
                    DurationButton(
                        duration: duration,
                        isSelected: selectedDuration == duration,
                        isActive: module.isActive
                    ) {
                        selectedDuration = duration
                        if module.isActive {
                            // Update duration on active session
                            module.activate(mode: selectedMode, duration: duration)
                        }
                    }
                }
            }

            // Activate button (if not active)
            if !module.isActive {
                Button(action: {
                    module.activate(mode: selectedMode, duration: selectedDuration)
                }) {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.top, 8)
            }
        }
    }
}

private struct DurationButton: View {
    let duration: PowerManager.Duration
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(duration.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .orange : .secondary)
    }
}

// MARK: - Remaining Time View

private struct RemainingTimeView: View {
    let endTime: Date
    @State private var remaining: TimeInterval = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.orange)

            Text("Ends in \(formattedRemaining)")
                .font(.subheadline)

            Spacer()

            // Progress indicator
            if let totalDuration = totalDuration {
                ProgressView(value: 1 - (remaining / totalDuration))
                    .frame(width: 60)
                    .tint(.orange)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .onReceive(timer) { _ in
            remaining = max(0, endTime.timeIntervalSinceNow)
        }
        .onAppear {
            remaining = max(0, endTime.timeIntervalSinceNow)
        }
    }

    private var formattedRemaining: String {
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private var totalDuration: TimeInterval? {
        // Estimate total duration based on remaining time
        // This is a simplification - in practice we'd store the original duration
        nil
    }
}

// MARK: - Settings View

struct KeepAwakeSettingsView: View {
    @ObservedObject var module: KeepAwakeModule

    var body: some View {
        Form {
            Section {
                Picker("Default Mode", selection: $module.defaultMode) {
                    ForEach(PowerManager.AwakeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Picker("Default Duration", selection: $module.defaultDuration) {
                    ForEach(PowerManager.Duration.allCases) { duration in
                        Text(duration.displayName).tag(duration)
                    }
                }
            } header: {
                Text("Defaults")
            }

            Section {
                Text("Keep-Awake prevents your Mac from sleeping. Use \"Prevent Display Sleep\" to keep the screen on, or \"Prevent System Sleep\" to allow the display to turn off while keeping the Mac awake.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Status View

struct KeepAwakeStatusView: View {
    @ObservedObject var module: KeepAwakeModule

    var body: some View {
        if module.isActive {
            HStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)

                if let remaining = module.powerManager.remainingTimeFormatted {
                    Text(remaining)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
