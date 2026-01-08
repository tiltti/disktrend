import AppKit
import SwiftUI

enum IconStyle: Int, CaseIterable {
    case pie = 0      // Pie/donut chart
    case battery = 1  // Battery style
    case dot = 2      // Color dot
    case bar = 3      // Vertical bar

    var name: String {
        switch self {
        case .pie: return String(localized: "icon.pie")
        case .battery: return String(localized: "icon.battery")
        case .dot: return String(localized: "icon.dot")
        case .bar: return String(localized: "icon.bar")
        }
    }
}

/// Creates colored menu bar icons
enum ColoredIcon {

    /// Main function that selects the correct icon based on settings
    static func icon(usedPercentage: Double, status: DiskStatus) -> NSImage {
        let styleRaw = UserDefaults.standard.integer(forKey: "iconStyle")
        let style = IconStyle(rawValue: styleRaw) ?? .pie

        switch style {
        case .pie:
            return diskPie(usedPercentage: usedPercentage, status: status, size: 16)
        case .battery:
            return diskBattery(usedPercentage: usedPercentage, status: status)
        case .dot:
            return statusDot(for: status, size: 12)
        case .bar:
            return diskBar(usedPercentage: usedPercentage, status: status)
        }
    }

    /// Creates a circular disk icon showing fill level as pie chart
    static func diskPie(usedPercentage: Double, status: DiskStatus, size: CGFloat = 14) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        let fillColor: NSColor
        switch status {
        case .healthy:
            fillColor = .systemGreen
        case .caution:
            fillColor = .systemYellow
        case .warning:
            fillColor = .systemOrange
        case .critical:
            fillColor = .systemRed
        }

        let center = NSPoint(x: size/2, y: size/2)
        let radius = (size - 2) / 2

        // Background (gray circle)
        let bgPath = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size - 2, height: size - 2))
        NSColor.white.withAlphaComponent(0.3).setFill()
        bgPath.fill()

        // Fill (pie slice - used space)
        let usedAngle = CGFloat(usedPercentage / 100) * 360
        let piePath = NSBezierPath()
        piePath.move(to: center)
        // Start from top (90 degrees) and draw clockwise
        piePath.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - usedAngle, clockwise: true)
        piePath.close()
        fillColor.setFill()
        piePath.fill()

        // Thin border
        let borderPath = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: size - 2, height: size - 2))
        NSColor.white.withAlphaComponent(0.6).setStroke()
        borderPath.lineWidth = 1
        borderPath.stroke()

        // Small center hole (makes it look like a donut - more disk-like)
        let holePath = NSBezierPath(ovalIn: NSRect(x: size/2 - 2, y: size/2 - 2, width: 4, height: 4))
        NSColor.black.withAlphaComponent(0.5).setFill()
        holePath.fill()

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    /// Creates a small color dot based on status
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

    /// Battery-style horizontal bar
    static func diskBattery(usedPercentage: Double, status: DiskStatus, width: CGFloat = 20, height: CGFloat = 10) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))

        image.lockFocus()

        let fillColor: NSColor
        switch status {
        case .healthy:
            fillColor = .systemGreen
        case .caution:
            fillColor = .systemYellow
        case .warning:
            fillColor = .systemOrange
        case .critical:
            fillColor = .systemRed
        }

        // Outer border
        let borderRect = NSRect(x: 0, y: 0, width: width - 3, height: height)
        let borderPath = NSBezierPath(roundedRect: borderRect, xRadius: 2, yRadius: 2)
        NSColor.white.withAlphaComponent(0.8).setStroke()
        borderPath.lineWidth = 1.5
        borderPath.stroke()

        // Nub on right side
        let nubRect = NSRect(x: width - 3, y: height/2 - 2, width: 3, height: 4)
        let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 1, yRadius: 1)
        NSColor.white.withAlphaComponent(0.8).setFill()
        nubPath.fill()

        // Fill bar
        let fillWidth = (width - 7) * CGFloat(min(usedPercentage, 100) / 100)
        if fillWidth > 0 {
            let fillRect = NSRect(x: 2, y: 2, width: fillWidth, height: height - 4)
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 1, yRadius: 1)
            fillColor.setFill()
            fillPath.fill()
        }

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    /// Vertical bar icon
    static func diskBar(usedPercentage: Double, status: DiskStatus, width: CGFloat = 8, height: CGFloat = 14) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))

        image.lockFocus()

        let fillColor: NSColor
        switch status {
        case .healthy:
            fillColor = .systemGreen
        case .caution:
            fillColor = .systemYellow
        case .warning:
            fillColor = .systemOrange
        case .critical:
            fillColor = .systemRed
        }

        // Outer border
        let borderRect = NSRect(x: 0, y: 0, width: width, height: height)
        let borderPath = NSBezierPath(roundedRect: borderRect, xRadius: 2, yRadius: 2)
        NSColor.white.withAlphaComponent(0.8).setStroke()
        borderPath.lineWidth = 1.5
        borderPath.stroke()

        // Fill from bottom to top
        let fillHeight = (height - 4) * CGFloat(min(usedPercentage, 100) / 100)
        if fillHeight > 0 {
            let fillRect = NSRect(x: 2, y: 2, width: width - 4, height: fillHeight)
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 1, yRadius: 1)
            fillColor.setFill()
            fillPath.fill()
        }

        image.unlockFocus()
        image.isTemplate = false

        return image
    }
}

// MARK: - NSImage Extension
extension NSImage {
    /// Tints the image with a specific color
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
