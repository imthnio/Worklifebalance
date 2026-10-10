import SwiftUI

private let digitFont = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)

@main
struct TBApp: App {
    @NSApplicationDelegateAdaptor(TBStatusItem.self) var appDelegate

    init() {
        TBStatusItem.shared = appDelegate
    }

    var body: some Scene {
        Settings {}
    }
}

extension Notification.Name {
    static let tbPopoverWillShow = Notification.Name("tbPopoverWillShow")
    static let tbPopoverDidClose = Notification.Name("tbPopoverDidClose")
}

class TBStatusItem: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var popover = NSPopover()
    private var statusBarItem: NSStatusItem?
    private var timer: TBTimer!
    private var termSignal: DispatchSourceSignal?
    static var shared: TBStatusItem!

    func applicationDidFinishLaunching(_: Notification) {
        // The installer quits the running copy with SIGTERM; exit normally so focus time is saved
        signal(SIGTERM, SIG_IGN)
        termSignal = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        termSignal?.setEventHandler { NSApp.terminate(nil) }
        termSignal?.resume()

        statusBarItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        statusBarItem?.button?.imagePosition = .imageLeft
        setIcon(working: false)
        statusBarItem?.button?.action = #selector(TBStatusItem.statusItemClicked(_:))
        statusBarItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusBarItem?.button?.target = self

        timer = TBTimer()
        let controller = NSHostingController(rootView: TBPopoverView(timer: timer))
        controller.sizingOptions = [.preferredContentSize]
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = controller

        // In-app shortcuts (e.g. ⌘Q) for the panel and the reminder banner
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let hotKeys = HotKeyCenter.shared
            if !hotKeys.suspended, hotKeys.hotKeys[.quit]?.matches(event) == true {
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }

    func setTitle(title: String?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.9
        paragraphStyle.alignment = NSTextAlignment.center

        let attributedTitle = NSAttributedString(
            string: title != nil ? " \(title!)" : "",
            attributes: [
                NSAttributedString.Key.font: digitFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
        statusBarItem?.button?.attributedTitle = attributedTitle
    }

    func setIcon(working: Bool) {
        statusBarItem?.button?.image = working ? workIcon : idleIcon
    }

    private let idleIcon = catHeadImage(filled: false)
    private let workIcon = catHeadImage(filled: true)

    func applicationWillTerminate(_: Notification) {
        // Keep the focus time of a round that is still running
        TBStats.shared.end()
    }

    func popoverDidClose(_: Notification) {
        NotificationCenter.default.post(name: .tbPopoverDidClose, object: nil)
    }

    func showPopover(_: AnyObject?) {
        if let button = statusBarItem?.button {
            NotificationCenter.default.post(name: .tbPopoverWillShow, object: nil)
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            popover.contentViewController?.view.window?.makeKey()
            // Don't start editing the duration field right away
            popover.contentViewController?.view.window?.makeFirstResponder(nil)
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }

    enum ClickAction {
        case togglePanel, startStop, none
    }

    /// Time of the previous left click on the menu bar icon
    private var lastLeftClick: TimeInterval?

    /*
     Right click (or Control-click) opens the panel, a left double click starts or stops the timer.
     On recent macOS the menu bar relays every click as a separate single click
     (clickCount is always 1), so double clicks are detected by timing.
     */
    func clickAction(isRightClick: Bool, clickCount: Int,
                     at now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> ClickAction {
        if isRightClick {
            lastLeftClick = nil
            return .togglePanel
        }
        if clickCount >= 2 {
            lastLeftClick = nil
            return .startStop
        }
        if let last = lastLeftClick, now - last <= NSEvent.doubleClickInterval {
            lastLeftClick = nil
            return .startStop
        }
        lastLeftClick = now
        return .none
    }

    @objc func statusItemClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }
        let isRightClick = event.type == .rightMouseUp ||
            (event.type == .leftMouseUp && event.modifierFlags.contains(.control))
        switch clickAction(isRightClick: isRightClick, clickCount: event.clickCount) {
        case .togglePanel:
            togglePopover(sender)
        case .startStop:
            closePopover(sender)
            timer.startStop()
        case .none:
            break
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
}
