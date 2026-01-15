import SwiftUI
import AppKit

// MARK: - Menu Bar Display Mode

enum MenuBarDisplayMode: Int, CaseIterable {
    case iconAndText = 0
    case iconOnly = 1
    case textOnly = 2

    var name: String {
        switch self {
        case .iconAndText: return String(localized: "display.iconAndText")
        case .iconOnly: return String(localized: "display.iconOnly")
        case .textOnly: return String(localized: "display.textOnly")
        }
    }

    var icon: String {
        switch self {
        case .iconAndText: return "text.below.photo"
        case .iconOnly: return "photo"
        case .textOnly: return "text.alignleft"
        }
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @ObservedObject var moduleManager: ModuleManager
    @AppStorage("menuBar.displayMode") private var displayMode: Int = 0

    private var mode: MenuBarDisplayMode {
        MenuBarDisplayMode(rawValue: displayMode) ?? .iconAndText
    }

    var body: some View {
        HStack(spacing: 4) {
            // Icon
            if mode != .textOnly {
                Image(systemName: primaryIcon)
                    .foregroundColor(iconColor)
            }

            // Status text
            if mode != .iconOnly {
                Text(statusText)
                    .font(.system(.caption, design: .monospaced))
            }
        }
    }

    private var primaryIcon: String {
        // Show coffee cup if Keep-Awake is active
        if moduleManager.isKeepAwakeActive {
            return "cup.and.saucer.fill"
        }
        // Default app icon
        return "menubar.dock.rectangle"
    }

    private var iconColor: Color? {
        if moduleManager.isKeepAwakeActive {
            return .orange
        }
        return nil
    }

    private var statusText: String {
        moduleManager.primaryStatusSummary
    }
}

// MARK: - Icon Generator (for colored icons)

enum IconStyle: Int, CaseIterable {
    case pie = 0
    case battery = 1
    case dot = 2
    case bar = 3

    var name: String {
        switch self {
        case .pie: return String(localized: "icon.pie")
        case .battery: return String(localized: "icon.battery")
        case .dot: return String(localized: "icon.dot")
        case .bar: return String(localized: "icon.bar")
        }
    }
}
