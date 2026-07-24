import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let caffeine = CaffeinationController()
    private let overlay = SplashOverlayController()
    private var statusItem: NSStatusItem!
    private var popup: PopupPanel!
    private var dashboard: DashboardView!
    private var closeTimer: Timer?
    private var statusRefreshTimer: Timer?
    private var outsideMonitor: Any?
    private var keyMonitor: Any?
    private var globalHotKey: GlobalHotKey?
    private var hotKeyAvailable = false

    private let presetDefaultsKey = "preferredCaffeinePreset"

    private var preferredPreset: CaffeinePreset {
        get {
            guard let stored = UserDefaults.standard.object(forKey: presetDefaultsKey) as? Int,
                  let preset = CaffeinePreset(rawValue: stored) else {
                return .untilTurnedOff
            }
            return preset
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: presetDefaultsKey)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configurePopup()
        configureGlobalHotKey()

        caffeine.onAutomaticStop = { [weak self] in
            self?.sessionExpired()
        }

        // A quiet first-run reveal teaches the interaction without changing power state.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.showPopup(autoCloseAfter: 5.5)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        caffeine.stop()
        closeTimer?.invalidate()
        statusRefreshTimer?.invalidate()
        globalHotKey?.unregister()
        removeEventMonitors()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = statusIcon(active: false, timed: false)
        button.imagePosition = .imageOnly
        button.toolTip = "Caffeinator — click or press ⌥⌘C"
        button.target = self
        button.action = #selector(statusItemPressed(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.setAccessibilityLabel("Caffeinator")
        button.setAccessibilityHelp("Click to toggle caffeine. Option-click to show status.")
    }

    private func configurePopup() {
        let size = NSSize(width: 356, height: 500)
        popup = PopupPanel(contentRect: NSRect(origin: .zero, size: size))
        dashboard = DashboardView(frame: NSRect(origin: .zero, size: size))
        dashboard.onToggle = { [weak self] in
            self?.toggleCaffeine()
        }
        dashboard.onSelectPreset = { [weak self] preset in
            self?.startOrUpdateSession(preset)
        }
        dashboard.onClose = { [weak self] in
            self?.closePopup()
        }
        popup.contentView = dashboard
    }

    private func configureGlobalHotKey() {
        let hotKey = GlobalHotKey { [weak self] in
            self?.toggleCaffeine()
        }
        hotKeyAvailable = hotKey.register()
        globalHotKey = hotKey
    }

    @objc private func statusItemPressed(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            toggleCaffeine()
            return
        }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else if event.modifierFlags.contains(.option) {
            showPopup(autoCloseAfter: nil)
        } else {
            toggleCaffeine()
        }
    }

    @objc private func menuToggle(_ sender: Any?) {
        toggleCaffeine()
    }

    @objc private func menuSelectPreset(_ sender: Any?) {
        guard let item = sender as? NSMenuItem,
              let value = item.representedObject as? NSNumber,
              let preset = CaffeinePreset(rawValue: value.intValue) else { return }
        startOrUpdateSession(preset)
    }

    @objc private func menuShowStatus(_ sender: Any?) {
        showPopup(autoCloseAfter: nil)
    }

    @objc private func menuQuit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func toggleCaffeine() {
        if caffeine.isActive {
            stopSession()
        } else {
            startOrUpdateSession(preferredPreset)
        }
    }

    private func startOrUpdateSession(_ preset: CaffeinePreset) {
        dashboard.errorMessage = nil
        preferredPreset = preset

        if caffeine.isActive {
            caffeine.updateSession(preset: preset)
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            updateUI()
            showPopup(autoCloseAfter: 4.6)
            return
        }

        do {
            try caffeine.start(preset: preset)
            updateUI()
            overlay.play(
                activating: true,
                from: statusItemAnchor(),
                sessionLabel: preset.overlayTitle
            )
            showPopup(autoCloseAfter: 5.4)
        } catch {
            dashboard.errorMessage = "macOS could not start the awake assertion. Reopen Caffeinator and try again."
            updateUI()
            showPopup(autoCloseAfter: nil)
        }
    }

    private func stopSession() {
        dashboard.errorMessage = nil
        caffeine.stop()
        updateUI()
        overlay.play(activating: false, from: statusItemAnchor(), sessionLabel: nil)
        showPopup(autoCloseAfter: 4.8)
    }

    private func sessionExpired() {
        updateUI()
        overlay.play(activating: false, from: statusItemAnchor(), sessionLabel: nil)
        showPopup(autoCloseAfter: 5.0)
    }

    private func updateUI() {
        dashboard.isActive = caffeine.isActive
        dashboard.startedAt = caffeine.startedAt
        dashboard.endsAt = caffeine.endsAt
        dashboard.selectedPreset = caffeine.isActive ? caffeine.preset : preferredPreset

        statusItem.button?.image = statusIcon(
            active: caffeine.isActive,
            timed: caffeine.isActive && caffeine.endsAt != nil
        )
        updateStatusTooltip()
        configureStatusRefresh()
    }

    private func updateStatusTooltip() {
        guard caffeine.isActive else {
            statusItem.button?.toolTip = hotKeyAvailable
                ? "Caffeinator — click or press ⌥⌘C"
                : "Caffeinator — click to caffeinate"
            return
        }

        if let remaining = caffeine.remaining {
            statusItem.button?.toolTip = "Caffeinated • \(compactDuration(remaining)) left • ⌥⌘C to stop"
        } else {
            statusItem.button?.toolTip = "Caffeinated until turned off • ⌥⌘C to stop"
        }
    }

    private func configureStatusRefresh() {
        statusRefreshTimer?.invalidate()
        statusRefreshTimer = nil
        guard caffeine.isActive && caffeine.endsAt != nil else { return }

        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateStatusTooltip()
        }
        RunLoop.main.add(timer, forMode: .common)
        statusRefreshTimer = timer
    }

    private func showPopup(autoCloseAfter delay: TimeInterval?) {
        dashboard.isActive = caffeine.isActive
        dashboard.startedAt = caffeine.startedAt
        dashboard.endsAt = caffeine.endsAt
        dashboard.selectedPreset = caffeine.isActive ? caffeine.preset : preferredPreset
        dashboard.hotKeyAvailable = hotKeyAvailable
        dashboard.beginRefreshing()
        positionPopup()
        popup.makeKeyAndOrderFront(nil)
        popup.makeFirstResponder(dashboard)

        closeTimer?.invalidate()
        if let delay {
            let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
                self?.closePopup()
            }
            RunLoop.main.add(timer, forMode: .common)
            closeTimer = timer
        }
        installEventMonitors()
    }

    private func closePopup() {
        popup?.orderOut(nil)
        dashboard?.stopRefreshing()
        closeTimer?.invalidate()
        closeTimer = nil
        removeEventMonitors()
    }

    private func installEventMonitors() {
        if outsideMonitor == nil {
            outsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopup()
            }
        }
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 {
                    self?.closePopup()
                    return nil
                }
                return event
            }
        }
    }

    private func removeEventMonitors() {
        if let outsideMonitor {
            NSEvent.removeMonitor(outsideMonitor)
            self.outsideMonitor = nil
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func positionPopup() {
        guard let buttonWindow = statusItem.button?.window else { return }
        let buttonFrame = buttonWindow.frame
        let screen = buttonWindow.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let visible = screen.visibleFrame
        let width = popup.frame.width
        let height = popup.frame.height
        let desiredX = buttonFrame.midX - width / 2
        let x = min(max(desiredX, visible.minX + 8), visible.maxX - width - 8)
        let top = buttonFrame.minY - 8
        let y = min(top - height, visible.maxY - height - 8)
        popup.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func statusItemAnchor() -> NSPoint? {
        guard let window = statusItem.button?.window else { return nil }
        return NSPoint(x: window.frame.midX, y: window.frame.midY)
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let toggleTitle = caffeine.isActive ? "Decaffeinate" : "Caffeinate now"
        let toggle = NSMenuItem(title: toggleTitle, action: #selector(menuToggle(_:)), keyEquivalent: "c")
        toggle.keyEquivalentModifierMask = [.command, .option]
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        let durationItem = NSMenuItem(title: "Session", action: nil, keyEquivalent: "")
        let durationMenu = NSMenu(title: "Session")
        for preset in CaffeinePreset.allCases {
            let item = NSMenuItem(title: preset.menuTitle, action: #selector(menuSelectPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = NSNumber(value: preset.rawValue)
            item.state = (caffeine.isActive ? caffeine.preset : preferredPreset) == preset ? .on : .off
            durationMenu.addItem(item)
        }
        durationItem.submenu = durationMenu
        menu.addItem(durationItem)

        let status = NSMenuItem(title: "Show status", action: #selector(menuShowStatus(_:)), keyEquivalent: "s")
        status.keyEquivalentModifierMask = [.command, .option]
        status.target = self
        menu.addItem(status)
        menu.addItem(.separator())

        let hint = NSMenuItem(title: sessionStatusTitle(), action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Caffeinator", action: #selector(menuQuit(_:)), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func sessionStatusTitle() -> String {
        guard caffeine.isActive else { return "Codex Remote • Standby" }
        if let remaining = caffeine.remaining {
            return "Codex Remote • \(compactDuration(remaining)) remaining"
        }
        return "Codex Remote • Ready"
    }

    private func compactDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(1, Int(ceil(interval / 60)))
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        }
        return "\(totalMinutes)m"
    }

    private func statusIcon(active: Bool, timed: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let cup = NSBezierPath(roundedRect: NSRect(x: 3, y: 3, width: 11, height: 8), xRadius: 2.5, yRadius: 2.5)
            if active {
                cup.fill()
            } else {
                cup.lineWidth = 1.35
                cup.stroke()
            }

            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 14, y: 9.5))
            handle.curve(to: NSPoint(x: 17.5, y: 7), controlPoint1: NSPoint(x: 18, y: 10), controlPoint2: NSPoint(x: 18.5, y: 7))
            handle.curve(to: NSPoint(x: 14, y: 5), controlPoint1: NSPoint(x: 17, y: 4.8), controlPoint2: NSPoint(x: 15.3, y: 5))
            handle.lineWidth = 1.35
            handle.lineCapStyle = .round
            handle.stroke()

            for index in 0..<2 {
                let x = CGFloat(6 + index * 5)
                let steam = NSBezierPath()
                steam.move(to: NSPoint(x: x, y: 13))
                steam.curve(
                    to: NSPoint(x: x + (active ? 0.5 : -0.5), y: 17),
                    controlPoint1: NSPoint(x: x - 1.5, y: 14.2),
                    controlPoint2: NSPoint(x: x + 1.5, y: 15.5)
                )
                steam.lineWidth = active ? 1.7 : 1.15
                steam.lineCapStyle = .round
                steam.stroke()
            }

            if active {
                let indicator = timed
                    ? NSBezierPath(ovalIn: NSRect(x: 0.3, y: 0.3, width: 3.7, height: 3.7))
                    : NSBezierPath(ovalIn: NSRect(x: 0.8, y: 0.8, width: 2.8, height: 2.8))
                if timed {
                    indicator.lineWidth = 1.1
                    indicator.stroke()
                } else {
                    indicator.fill()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
