import AppKit
import SwiftUI

/// Luo värillisen menu bar -ikonin
enum ColoredIcon {

    /// Luo värillinen levy-ikoni statuksen mukaan
    static func diskIcon(for status: DiskStatus, size: CGFloat = 18) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .medium)

        let symbolName: String
        let color: NSColor

        switch status {
        case .healthy:
            symbolName = "internaldrive.fill"
            color = .systemGreen
        case .caution:
            symbolName = "internaldrive.fill"
            color = .systemYellow
        case .warning:
            symbolName = "externaldrive.fill.badge.exclamationmark"
            color = .systemOrange
        case .critical:
            symbolName = "externaldrive.fill.badge.xmark"
            color = .systemRed
        }

        guard let baseImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Disk status") else {
            return NSImage()
        }

        let coloredImage = baseImage.withSymbolConfiguration(config)?.image(with: color)
        return coloredImage ?? baseImage
    }

    /// Luo pieni väripallo statuksen mukaan
    static func statusDot(for status: DiskStatus, size: CGFloat = 10) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        let color: NSColor
        switch status {
        case .healthy:
            color = .systemGreen
        case .caution:
            color = .systemYellow
        case .warning:
            color = .systemOrange
        case .critical:
            color = .systemRed
        }

        color.setFill()
        let rect = NSRect(x: 1, y: 1, width: size - 2, height: size - 2)
        let path = NSBezierPath(ovalIn: rect)
        path.fill()

        image.unlockFocus()
        image.isTemplate = false

        return image
    }
}

// MARK: - NSImage Extension
extension NSImage {
    /// Värjää kuvan tietyllä värillä
    func image(with tintColor: NSColor) -> NSImage {
        if self.isTemplate == false {
            return self
        }

        let image = self.copy() as! NSImage
        image.lockFocus()

        tintColor.set()

        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)

        image.unlockFocus()
        image.isTemplate = false

        return image
    }
}

