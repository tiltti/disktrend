import Foundation

/// Localized strings
enum L10n {
    // App
    static let appName = String(localized: "app.name")
    static func appVersion(_ version: String) -> String {
        String(format: String(localized: "app.version"), version)
    }
    static let appDescription = String(localized: "app.description")

    // Menu Bar
    static let menubarUnknown = String(localized: "menubar.unknown")

    // Popover
    static let popoverTitle = String(localized: "popover.title")
    static let popoverNoVolumes = String(localized: "popover.noVolumes")
    static let popoverRefresh = String(localized: "popover.refresh")
    static let popoverSettings = String(localized: "popover.settings")
    static let popoverQuit = String(localized: "popover.quit")

    // Volume
    static let volumeTotal = String(localized: "volume.total")
    static let volumeUsed = String(localized: "volume.used")
    static let volumeFree = String(localized: "volume.free")

    // Trend
    static func trendTitle(_ hours: Int) -> String {
        String(format: String(localized: "trend.title"), hours)
    }
    static let trendChange = String(localized: "trend.change")
    static let trendEstimate = String(localized: "trend.estimate")
    static let trendStable = String(localized: "trend.stable")
    static func trendPerDay(_ amount: String) -> String {
        String(format: String(localized: "trend.perDay"), amount)
    }
    static func trendMeasurements(_ count: Int) -> String {
        String(format: String(localized: "trend.measurements"), count)
    }
    static let trendFullIn24h = String(localized: "trend.fullIn24h")
    static func trendFullInDays(_ days: Int) -> String {
        String(format: String(localized: "trend.fullInDays"), days)
    }
    static func trendFullInDaysNormal(_ days: Int) -> String {
        String(format: String(localized: "trend.fullInDaysNormal"), days)
    }

    // Settings - Tabs
    static let settingsGeneral = String(localized: "settings.general")
    static let settingsAlerts = String(localized: "settings.alerts")
    static let settingsAbout = String(localized: "settings.about")

    // Settings - General
    static let settingsDisplayMode = String(localized: "settings.displayMode")
    static let settingsIconStyle = String(localized: "settings.iconStyle")
    static let settingsUpdateInterval = String(localized: "settings.updateInterval")
    static let settingsInterval10s = String(localized: "settings.interval.10s")
    static let settingsInterval30s = String(localized: "settings.interval.30s")
    static let settingsInterval1m = String(localized: "settings.interval.1m")
    static let settingsInterval5m = String(localized: "settings.interval.5m")
    static let settingsDecimals = String(localized: "settings.decimals")
    static let settingsLaunchAtLogin = String(localized: "settings.launchAtLogin")

    // Settings - Alerts
    static func settingsWarningThreshold(_ percent: Int) -> String {
        String(format: String(localized: "settings.warningThreshold"), percent)
    }
    static func settingsCriticalThreshold(_ percent: Int) -> String {
        String(format: String(localized: "settings.criticalThreshold"), percent)
    }
    static let settingsThresholdDescription = String(localized: "settings.thresholdDescription")
}
