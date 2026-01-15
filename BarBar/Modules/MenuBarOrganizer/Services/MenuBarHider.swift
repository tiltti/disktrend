import AppKit

@MainActor
final class MenuBarHider {

    private(set) var isHidden = false
    var onStateChanged: (() -> Void)?

    // TWO items:
    // 1. separator - user drags THIS to position the dividing line, this expands when hiding
    // 2. toggle - user clicks THIS to hide/show, stays visible always
    private var separatorItem: NSStatusItem?
    private var toggleItem: NSStatusItem?

    private let expandedWidth: CGFloat = 10000

    init() {
        setup()
    }

    private func setup() {
        // Creation order: FIRST created = RIGHTMOST in menu bar

        // 1. Create TOGGLE first → rightmost (near clock)
        //    This is ONLY for clicking, don't drag this
        toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = toggleItem?.button {
            btn.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Toggle hidden icons")
            btn.action = #selector(toggleClicked)
            btn.target = self
        }

        // 2. Create SEPARATOR second → left of toggle
        //    User should ⌘+drag THIS to position the dividing line
        separatorItem = NSStatusBar.system.statusItem(withLength: 16)
        if let btn = separatorItem?.button {
            btn.title = "|"
            btn.action = #selector(toggleClicked)
            btn.target = self
        }
    }

    @objc private func toggleClicked() {
        toggle()
    }

    private func toggle() {
        isHidden.toggle()

        if isHidden {
            // EXPAND separator to push items off screen
            separatorItem?.length = expandedWidth
            separatorItem?.button?.title = ""  // Title goes off-screen anyway
            toggleItem?.button?.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil)
        } else {
            // COLLAPSE separator
            separatorItem?.length = 16
            separatorItem?.button?.title = "|"
            toggleItem?.button?.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
        }

        onStateChanged?()
    }

    func expand() { if !isHidden { toggle() } }
    func collapse() { if isHidden { toggle() } }
    func toggleVisibility() { toggle() }

    func cleanup() {
        if let item = separatorItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        if let item = toggleItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        separatorItem = nil
        toggleItem = nil
    }

    func loadSettings() {}
    var isExpanded: Bool { !isHidden }
    var separatorStyle: SeparatorStyle = .dots
    var hiddenAreaWidth: CGFloat = 10000

    enum SeparatorStyle: Int, CaseIterable {
        case chevron = 0, dots = 1, line = 2, minimal = 3
        var expandedIcon: String { "ellipsis" }
        var collapsedIcon: String { "chevron.left.2" }
        var name: String {
            switch self {
            case .chevron: return "Chevron"
            case .dots: return "Dots"
            case .line: return "Lines"
            case .minimal: return "Minimal"
            }
        }
    }
}
