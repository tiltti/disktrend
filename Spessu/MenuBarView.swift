import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var diskMonitor: DiskMonitor

    var body: some View {
        HStack(spacing: 4) {
            // Status indicator icon
            Image(nsImage: diskGaugeImage)

            // Free space as text (if enabled in settings)
            if diskMonitor.showTextInMenuBar {
                if let primary = diskMonitor.primaryVolume {
                    Text(primary.freeBytes.formattedBytesShort)
                        .monospacedDigit()
                } else {
                    Text("--")
                }
            }
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
