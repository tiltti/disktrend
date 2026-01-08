import SwiftUI
import AppKit

/// Menu bar display mode
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
}

struct MenuBarView: View {
    @ObservedObject var diskMonitor: DiskMonitor

    var body: some View {
        HStack(spacing: 4) {
            // Status indicator icon
            if diskMonitor.displayMode != .textOnly {
                Image(nsImage: diskGaugeImage)
            }

            // Free space as text
            if diskMonitor.displayMode != .iconOnly {
                if let primary = diskMonitor.primaryVolume {
                    Text(primary.freeBytes.formattedBytesShort)
                        .monospacedDigit()
                } else {
                    Text("--")
                }
            }
        }
        .onAppear {
            print("[MenuBarView] displayMode: \(diskMonitor.displayMode), volumes: \(diskMonitor.volumes.count)")
        }
    }

    private var diskGaugeImage: NSImage {
        guard let primary = diskMonitor.primaryVolume else {
            return ColoredIcon.icon(usedPercentage: 0, status: .healthy)
        }
        return ColoredIcon.icon(
            usedPercentage: primary.usedPercentage,
            status: primary.status
        )
    }
}
