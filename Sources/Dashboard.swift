import AppKit

final class PopupPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class DashboardView: NSView {
    private enum HoverTarget: Equatable {
        case cup
        case preset(Int)
    }

    var isActive = false {
        didSet {
            startedAt = isActive ? startedAt ?? Date() : nil
            needsDisplay = true
        }
    }
    var startedAt: Date? {
        didSet { needsDisplay = true }
    }
    var endsAt: Date? {
        didSet { needsDisplay = true }
    }
    var selectedPreset: CaffeinePreset = .untilTurnedOff {
        didSet { needsDisplay = true }
    }
    var errorMessage: String? {
        didSet { needsDisplay = true }
    }
    var hotKeyAvailable = true {
        didSet { needsDisplay = true }
    }

    var onToggle: (() -> Void)?
    var onSelectPreset: ((CaffeinePreset) -> Void)?
    var onClose: (() -> Void)?

    private var hoveredTarget: HoverTarget?
    private var interactionTrackingAreas: [NSTrackingArea] = []
    private var refreshTimer: Timer?
    private var animationEndsAt = Date.distantPast

    private var cupRect: NSRect {
        NSRect(x: bounds.midX - 72, y: 282, width: 144, height: 144)
    }

    private var presetRects: [NSRect] {
        let left: CGFloat = 20
        let gap: CGFloat = 8
        let width = (bounds.width - left * 2 - gap * 3) / 4
        return (0..<4).map { index in
            NSRect(x: left + CGFloat(index) * (width + gap), y: 151, width: width, height: 38)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Caffeinator")
        setAccessibilityHelp("Toggle caffeine or choose a timed session.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginRefreshing() {
        animationEndsAt = Date(timeIntervalSinceNow: 5.8)
        startFastRefresh()
    }

    func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func startFastRefresh() {
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.needsDisplay = true
            if Date() >= self.animationEndsAt {
                self.startSlowRefresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func startSlowRefresh() {
        refreshTimer?.invalidate()
        guard isActive else {
            refreshTimer = nil
            return
        }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func brieflyAnimate() {
        animationEndsAt = Date(timeIntervalSinceNow: 0.65)
        startFastRefresh()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        rebuildTrackingAreas()
    }

    private func rebuildTrackingAreas() {
        interactionTrackingAreas.forEach(removeTrackingArea)
        interactionTrackingAreas.removeAll()

        let cupArea = NSTrackingArea(
            rect: cupRect,
            options: [.mouseEnteredAndExited, .activeAlways, .cursorUpdate],
            owner: self,
            userInfo: ["target": "cup"]
        )
        addTrackingArea(cupArea)
        interactionTrackingAreas.append(cupArea)

        for (index, rect) in presetRects.enumerated() {
            let area = NSTrackingArea(
                rect: rect,
                options: [.mouseEnteredAndExited, .activeAlways, .cursorUpdate],
                owner: self,
                userInfo: ["target": "preset-\(index)"]
            )
            addTrackingArea(area)
            interactionTrackingAreas.append(area)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard let target = event.trackingArea?.userInfo?["target"] as? String else { return }
        if target == "cup" {
            hoveredTarget = .cup
        } else if let index = Int(target.replacingOccurrences(of: "preset-", with: "")) {
            hoveredTarget = .preset(index)
        }
        brieflyAnimate()
    }

    override func mouseExited(with event: NSEvent) {
        hoveredTarget = nil
        brieflyAnimate()
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if cupRect.contains(point) {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            onToggle?()
            return
        }

        for (index, rect) in presetRects.enumerated() where rect.contains(point) {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            onSelectPreset?(CaffeinePreset.allCases[index])
            return
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onClose?()
            return
        }
        if event.keyCode == 36 || event.keyCode == 49 {
            onToggle?()
            return
        }
        if let character = event.charactersIgnoringModifiers,
           let number = Int(character),
           (1...4).contains(number) {
            onSelectPreset?(CaffeinePreset.allCases[number - 1])
            return
        }
        super.keyDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawPanel()
        drawHeader()
        drawMainControl()
        drawCopy()
        drawSessionPicker()
        drawStatusCard()
        drawFooter()
    }

    private func drawPanel() {
        let panelRect = bounds.insetBy(dx: 1, dy: 1)
        let path = CaffeinatorTheme.roundedPath(panelRect, radius: 30)
        let gradient = NSGradient(colorsAndLocations:
            (NSColor(calibratedRed: 0.085, green: 0.103, blue: 0.158, alpha: 0.995), 0),
            (CaffeinatorTheme.panelTop, 0.42),
            (CaffeinatorTheme.panelBottom, 1)
        )!
        gradient.draw(in: path, angle: -90)

        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        let glowRect = NSRect(x: bounds.midX - 175, y: 260, width: 350, height: 260)
        let glow = NSGradient(colors: [
            (isActive ? CaffeinatorTheme.amber : CaffeinatorTheme.cool).withAlphaComponent(0.095),
            NSColor.clear
        ])!
        glow.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: .zero)
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.105).setStroke()
        let border = CaffeinatorTheme.roundedPath(panelRect, radius: 30)
        border.lineWidth = 1
        border.stroke()

        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: 30, y: bounds.maxY - 1.5))
        highlight.line(to: NSPoint(x: bounds.maxX - 30, y: bounds.maxY - 1.5))
        NSColor.white.withAlphaComponent(0.14).setStroke()
        highlight.lineWidth = 1
        highlight.stroke()
    }

    private func drawHeader() {
        CaffeinatorTheme.drawText(
            "CAFFEINATOR",
            in: NSRect(x: 22, y: bounds.maxY - 49, width: 155, height: 20),
            font: .systemFont(ofSize: 12, weight: .bold),
            color: CaffeinatorTheme.cream,
            kern: 1.75
        )
        CaffeinatorTheme.drawText(
            "1.1",
            in: NSRect(x: 157, y: bounds.maxY - 48, width: 30, height: 16),
            font: .monospacedSystemFont(ofSize: 8.5, weight: .medium),
            color: NSColor.white.withAlphaComponent(0.34),
            kern: 0.3
        )

        let badgeWidth: CGFloat = isActive ? 108 : 80
        let badgeRect = NSRect(x: bounds.maxX - badgeWidth - 21, y: bounds.maxY - 53, width: badgeWidth, height: 28)
        let accent = isActive ? CaffeinatorTheme.mint : CaffeinatorTheme.cool
        accent.withAlphaComponent(0.10).setFill()
        CaffeinatorTheme.roundedPath(badgeRect, radius: 14).fill()
        accent.withAlphaComponent(0.30).setStroke()
        let badgeBorder = CaffeinatorTheme.roundedPath(badgeRect.insetBy(dx: 0.5, dy: 0.5), radius: 13.5)
        badgeBorder.lineWidth = 1
        badgeBorder.stroke()

        let dotRect = NSRect(x: badgeRect.minX + 11, y: badgeRect.midY - 3, width: 6, height: 6)
        accent.setFill()
        NSBezierPath(ovalIn: dotRect).fill()
        if isActive {
            accent.withAlphaComponent(0.20).setFill()
            NSBezierPath(ovalIn: dotRect.insetBy(dx: -4, dy: -4)).fill()
        }
        CaffeinatorTheme.drawText(
            isActive ? "REMOTE READY" : "STANDBY",
            in: NSRect(x: badgeRect.minX + 24, y: badgeRect.minY + 6, width: badgeRect.width - 29, height: 16),
            font: .systemFont(ofSize: 8.2, weight: .bold),
            color: accent,
            kern: 0.55
        )
    }

    private func drawMainControl() {
        let rect = cupRect
        let accent = isActive ? CaffeinatorTheme.amber : CaffeinatorTheme.cool
        let isHovered = hoveredTarget == .cup
        let time = Date().timeIntervalSinceReferenceDate
        let pulse = isActive ? (sin(time * 2.7) + 1) / 2 : 0
        let hoverScale: CGFloat = isHovered ? 1.035 : 1
        let visualRect = NSRect(
            x: rect.midX - rect.width * hoverScale / 2,
            y: rect.midY - rect.height * hoverScale / 2,
            width: rect.width * hoverScale,
            height: rect.height * hoverScale
        )

        let outerGlow = NSBezierPath(ovalIn: visualRect.insetBy(dx: -13 - pulse * 3, dy: -13 - pulse * 3))
        accent.withAlphaComponent(isActive ? 0.10 + pulse * 0.045 : (isHovered ? 0.10 : 0.055)).setFill()
        outerGlow.fill()

        let circle = NSBezierPath(ovalIn: visualRect)
        let gradient = NSGradient(colorsAndLocations:
            (NSColor.white.withAlphaComponent(0.12), 0),
            (NSColor.white.withAlphaComponent(0.04), 0.52),
            (NSColor.black.withAlphaComponent(0.12), 1)
        )!
        gradient.draw(in: circle, angle: -90)

        accent.withAlphaComponent(isHovered ? 0.58 : 0.30).setStroke()
        circle.lineWidth = isHovered ? 1.6 : 1
        circle.stroke()

        let inner = NSBezierPath(ovalIn: visualRect.insetBy(dx: 10, dy: 10))
        if isActive {
            let dash: [CGFloat] = [3, 7]
            inner.setLineDash(dash, count: dash.count, phase: CGFloat(time * -9).truncatingRemainder(dividingBy: 10))
        }
        accent.withAlphaComponent(isActive ? 0.28 : 0.09).setStroke()
        inner.lineWidth = 1
        inner.stroke()

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        drawCoffeeCup(
            in: context,
            center: NSPoint(x: visualRect.midX, y: visualRect.midY - 7),
            scale: isHovered ? 1.03 : 1,
            active: isActive,
            steamPhase: time.truncatingRemainder(dividingBy: 6)
        )
    }

    private func drawCopy() {
        if let errorMessage {
            CaffeinatorTheme.drawText(
                "COULDN’T CAFFEINATE",
                in: NSRect(x: 24, y: 246, width: bounds.width - 48, height: 24),
                font: .systemFont(ofSize: 16.5, weight: .bold),
                color: CaffeinatorTheme.coral,
                alignment: .center,
                kern: 0.35
            )
            CaffeinatorTheme.drawText(
                errorMessage,
                in: NSRect(x: 36, y: 213, width: bounds.width - 72, height: 34),
                font: .systemFont(ofSize: 10.5, weight: .regular),
                color: CaffeinatorTheme.mutedCream,
                alignment: .center,
                lineHeight: 14
            )
            return
        }

        CaffeinatorTheme.drawText(
            isActive ? "REMOTE MODE IS LIVE" : "READY FOR REMOTE WORK",
            in: NSRect(x: 22, y: 246, width: bounds.width - 44, height: 25),
            font: .systemFont(ofSize: 17.5, weight: .bold),
            color: CaffeinatorTheme.cream,
            alignment: .center,
            kern: 0.38
        )
        CaffeinatorTheme.drawText(
            subtitleText(),
            in: NSRect(x: 26, y: 221, width: bounds.width - 52, height: 20),
            font: .systemFont(ofSize: 11.5, weight: .regular),
            color: CaffeinatorTheme.mutedCream,
            alignment: .center
        )
    }

    private func drawSessionPicker() {
        CaffeinatorTheme.drawText(
            "SESSION",
            in: NSRect(x: 21, y: 196, width: 80, height: 14),
            font: .systemFont(ofSize: 8.5, weight: .bold),
            color: NSColor.white.withAlphaComponent(0.42),
            kern: 1.35
        )
        CaffeinatorTheme.drawText(
            isActive ? sessionCaption() : "Choose & start",
            in: NSRect(x: bounds.maxX - 151, y: 195, width: 130, height: 15),
            font: .systemFont(ofSize: 9.5, weight: .medium),
            color: (isActive ? CaffeinatorTheme.mint : CaffeinatorTheme.cool).withAlphaComponent(0.82),
            alignment: .right
        )

        for (index, preset) in CaffeinePreset.allCases.enumerated() {
            let rect = presetRects[index]
            let selected = selectedPreset == preset
            let hovered = hoveredTarget == .preset(index)
            let selectionAccent = isActive ? CaffeinatorTheme.amber : CaffeinatorTheme.cool

            (selected
                ? selectionAccent.withAlphaComponent(0.16)
                : NSColor.white.withAlphaComponent(hovered ? 0.085 : 0.040)
            ).setFill()
            CaffeinatorTheme.roundedPath(rect, radius: 12).fill()

            (selected
                ? selectionAccent.withAlphaComponent(0.48)
                : NSColor.white.withAlphaComponent(hovered ? 0.16 : 0.075)
            ).setStroke()
            let border = CaffeinatorTheme.roundedPath(rect.insetBy(dx: 0.5, dy: 0.5), radius: 11.5)
            border.lineWidth = 1
            border.stroke()

            CaffeinatorTheme.drawText(
                preset.compactTitle,
                in: NSRect(x: rect.minX + 4, y: rect.minY + 11, width: rect.width - 8, height: 17),
                font: .systemFont(ofSize: preset == .untilTurnedOff ? 16 : 10.5, weight: .semibold),
                color: selected
                    ? (isActive ? CaffeinatorTheme.brightAmber : CaffeinatorTheme.cool)
                    : CaffeinatorTheme.cream.withAlphaComponent(hovered ? 1 : 0.72),
                alignment: .center,
                kern: preset == .untilTurnedOff ? 0 : 0.1
            )
        }
    }

    private func drawStatusCard() {
        let cardRect = NSRect(x: 20, y: 70, width: bounds.width - 40, height: 61)
        NSColor.white.withAlphaComponent(0.045).setFill()
        CaffeinatorTheme.roundedPath(cardRect, radius: 18).fill()
        NSColor.white.withAlphaComponent(0.08).setStroke()
        let cardBorder = CaffeinatorTheme.roundedPath(cardRect.insetBy(dx: 0.5, dy: 0.5), radius: 17.5)
        cardBorder.lineWidth = 1
        cardBorder.stroke()

        let accent = isActive ? CaffeinatorTheme.mint : CaffeinatorTheme.cool
        let shieldRect = NSRect(x: cardRect.minX + 14, y: cardRect.minY + 14, width: 33, height: 33)
        accent.withAlphaComponent(0.12).setFill()
        NSBezierPath(ovalIn: shieldRect).fill()
        CaffeinatorTheme.drawText(
            isActive ? "✓" : "○",
            in: NSRect(x: shieldRect.minX, y: shieldRect.minY + 6, width: shieldRect.width, height: 20),
            font: .systemFont(ofSize: 14, weight: .bold),
            color: accent,
            alignment: .center
        )

        CaffeinatorTheme.drawText(
            "AWAKE SHIELD",
            in: NSRect(x: cardRect.minX + 59, y: cardRect.minY + 32, width: 135, height: 14),
            font: .systemFont(ofSize: 8.5, weight: .bold),
            color: CaffeinatorTheme.mutedCream,
            kern: 1.15
        )
        CaffeinatorTheme.drawText(
            isActive ? "Display + system protected" : "Sleep behaves normally",
            in: NSRect(x: cardRect.minX + 59, y: cardRect.minY + 12, width: 178, height: 18),
            font: .systemFont(ofSize: 11.5, weight: .semibold),
            color: CaffeinatorTheme.cream
        )

        CaffeinatorTheme.drawText(
            statusValue(),
            in: NSRect(x: cardRect.maxX - 91, y: cardRect.minY + 21, width: 72, height: 20),
            font: .monospacedDigitSystemFont(ofSize: 11.5, weight: .medium),
            color: accent,
            alignment: .right,
            kern: 0.15
        )
    }

    private func drawFooter() {
        if hotKeyAvailable {
            let keyLabels = ["⌥", "⌘", "C"]
            let keySize = NSSize(width: 22, height: 20)
            let gap: CGFloat = 5
            let totalKeysWidth = CGFloat(keyLabels.count) * keySize.width + CGFloat(keyLabels.count - 1) * gap
            let groupWidth = totalKeysWidth + 10 + 116
            let startX = bounds.midX - groupWidth / 2

            for (index, label) in keyLabels.enumerated() {
                let rect = NSRect(
                    x: startX + CGFloat(index) * (keySize.width + gap),
                    y: 27,
                    width: keySize.width,
                    height: keySize.height
                )
                NSColor.white.withAlphaComponent(0.055).setFill()
                CaffeinatorTheme.roundedPath(rect, radius: 6).fill()
                NSColor.white.withAlphaComponent(0.11).setStroke()
                CaffeinatorTheme.roundedPath(rect.insetBy(dx: 0.5, dy: 0.5), radius: 5.5).stroke()
                CaffeinatorTheme.drawText(
                    label,
                    in: NSRect(x: rect.minX, y: rect.minY + 3, width: rect.width, height: 15),
                    font: .systemFont(ofSize: 10, weight: .semibold),
                    color: CaffeinatorTheme.cream.withAlphaComponent(0.72),
                    alignment: .center
                )
            }
            CaffeinatorTheme.drawText(
                "TOGGLE ANYWHERE",
                in: NSRect(x: startX + totalKeysWidth + 10, y: 30, width: 116, height: 14),
                font: .systemFont(ofSize: 7.7, weight: .bold),
                color: NSColor.white.withAlphaComponent(0.36),
                kern: 0.7
            )
        } else {
            CaffeinatorTheme.drawText(
                isActive ? "CLICK THE CUP TO LET YOUR MAC REST" : "CLICK THE CUP TO CAFFEINATE",
                in: NSRect(x: 20, y: 29, width: bounds.width - 40, height: 15),
                font: .systemFont(ofSize: 8.5, weight: .bold),
                color: NSColor.white.withAlphaComponent(0.34),
                alignment: .center,
                kern: 1.05
            )
        }
    }

    private func subtitleText() -> String {
        guard isActive else { return "Click the cup, or pick a session below." }
        if let endsAt {
            return "Protected for another \(friendlyRemaining(endsAt.timeIntervalSinceNow))."
        }
        return "Display and system sleep are protected."
    }

    private func sessionCaption() -> String {
        if let endsAt {
            return "\(friendlyRemaining(endsAt.timeIntervalSinceNow)) left"
        }
        return "Until turned off"
    }

    private func statusValue() -> String {
        guard isActive else { return "OFF" }
        if let endsAt {
            return clockRemaining(endsAt.timeIntervalSinceNow)
        }
        return elapsedString()
    }

    private func friendlyRemaining(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        if seconds >= 3600 {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        }
        if seconds >= 60 {
            return "\(max(1, seconds / 60))m"
        }
        return "\(seconds)s"
    }

    private func clockRemaining(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func elapsedString() -> String {
        guard let startedAt else { return "00:00" }
        let total = max(0, Int(Date().timeIntervalSince(startedAt)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
