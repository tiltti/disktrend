import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var diskMonitor: DiskMonitor

    var body: some View {
        HStack(spacing: 4) {
            // Väripallo statuksen mukaan
            Image(nsImage: statusDotImage)

            // Vapaa tila tekstinä
            if let primary = diskMonitor.primaryVolume {
                Text(primary.freeBytes.formattedBytesShort)
                    .monospacedDigit()
            } else {
                Text("--")
            }
        }
    }

    private var statusDotImage: NSImage {
        let status = diskMonitor.primaryVolume?.status ?? .healthy
        return ColoredIcon.statusDot(for: status, size: 12)
    }
}
