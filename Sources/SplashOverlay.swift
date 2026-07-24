import AppKit

private struct CoffeeParticle {
    let angle: CGFloat
    let speed: CGFloat
    let size: CGFloat
    let delay: CGFloat
    let stretch: CGFloat
}

final class OverlayPanel: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class SplashOverlayView: NSView {
    private let activating: Bool
    private let startPoint: NSPoint
    private let impactPoint: NSPoint
    private let sessionLabel: String?
    private let particles: [CoffeeParticle]
    private var timer: Timer?
    private var startedAt = CACurrentMediaTime()
    private var progress: CGFloat = 0
    private let completion: () -> Void

    init(
        frame: NSRect,
        activating: Bool,
        startPoint: NSPoint,
        sessionLabel: String?,
        completion: @escaping () -> Void
    ) {
        self.activating = activating
        self.startPoint = startPoint
        self.sessionLabel = sessionLabel
        self.completion = completion

        let width = frame.width
        let height = frame.height
        self.impactPoint = NSPoint(
            x: min(max(width * 0.58, 260), width - 260),
            y: min(max(height * 0.52, 240), height - 220)
        )

        var seeded: [CoffeeParticle] = []
        for index in 0..<36 {
            let unit = CGFloat((index * 47) % 101) / 101
            let secondary = CGFloat((index * 71 + 13) % 97) / 97
            seeded.append(
                CoffeeParticle(
                    angle: (.pi * 0.14) + unit * (.pi * 0.72),
                    speed: 110 + secondary * 245,
                    size: 3.5 + CGFloat(index % 5) * 1.6,
                    delay: CGFloat(index % 7) * 0.018,
                    stretch: 0.9 + CGFloat(index % 4) * 0.42
                )
            )
        }
        self.particles = seeded

        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        startedAt = CACurrentMediaTime()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func tick() {
        let duration = activating ? 1.85 : 1.35
        progress = CGFloat((CACurrentMediaTime() - startedAt) / duration)
        needsDisplay = true
        if progress >= 1 {
            timer?.invalidate()
            timer = nil
            completion()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        activating ? drawActivation(in: context) : drawDeactivation(in: context)
    }

    private func drawActivation(in context: CGContext) {
        let throwEnd: CGFloat = 0.48
        let throwProgress = min(progress / throwEnd, 1)
        let arcControl = NSPoint(
            x: lerp(startPoint.x, impactPoint.x, 0.46),
            y: max(startPoint.y, impactPoint.y) + 165
        )
        let cupPoint = pointOnQuadratic(startPoint, arcControl, impactPoint, CaffeinatorTheme.eased(throwProgress))

        if progress < 0.56 {
            let cupAlpha = min(1, (0.56 - progress) / 0.08)
            drawCoffeeCup(
                in: context,
                center: cupPoint,
                scale: 0.80 + throwProgress * 0.30,
                active: true,
                rotation: -0.18 - throwProgress * 1.08,
                steamPhase: -1,
                alpha: cupAlpha
            )

            drawCoffeeTrail(in: context, from: cupPoint, throwProgress: throwProgress)
        }

        if progress > 0.33 {
            let splashProgress = (progress - 0.33) / 0.47
            drawSplash(in: context, progress: splashProgress)
        }

        if progress > 0.49 {
            let toastProgress = CaffeinatorTheme.smoothstep((progress - 0.49) / 0.20)
            drawToast(
                in: context,
                title: "MAC CAFFEINATED",
                subtitle: "CODEX REMOTE  •  \(sessionLabel ?? "READY")",
                accent: CaffeinatorTheme.mint,
                alpha: toastProgress * min(1, (1 - progress) / 0.12),
                yOffset: (1 - toastProgress) * -10
            )
        }
    }

    private func drawCoffeeTrail(in context: CGContext, from cupPoint: NSPoint, throwProgress: CGFloat) {
        guard throwProgress > 0.10 else { return }
        let count = Int(min(12, floor(throwProgress * 16)))
        for index in 0..<count {
            let lag = CGFloat(index + 1) * 0.032
            let trailT = max(0, throwProgress - lag)
            let arcControl = NSPoint(
                x: lerp(startPoint.x, impactPoint.x, 0.46),
                y: max(startPoint.y, impactPoint.y) + 165
            )
            let point = pointOnQuadratic(startPoint, arcControl, impactPoint, CaffeinatorTheme.eased(trailT))
            let size = max(2, 8 - CGFloat(index) * 0.45)
            let drop = NSBezierPath(ovalIn: NSRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size * 1.35))
            CaffeinatorTheme.caramel.withAlphaComponent(max(0.08, 0.68 - CGFloat(index) * 0.048)).setFill()
            drop.fill()
        }
    }

    private func drawSplash(in context: CGContext, progress rawProgress: CGFloat) {
        let t = min(max(rawProgress, 0), 1)
        let ringProgress = CaffeinatorTheme.eased(t)

        if t < 0.85 {
            let glowSize = 42 + ringProgress * 185
            let glow = NSBezierPath(ovalIn: NSRect(
                x: impactPoint.x - glowSize / 2,
                y: impactPoint.y - glowSize * 0.22,
                width: glowSize,
                height: glowSize * 0.44
            ))
            CaffeinatorTheme.amber.withAlphaComponent((1 - t) * 0.16).setFill()
            glow.fill()
        }

        for particle in particles {
            let local = min(max((t - particle.delay) / (1 - particle.delay), 0), 1)
            guard local > 0 && local < 0.92 else { continue }
            let distance = particle.speed * local
            let x = impactPoint.x + cos(particle.angle) * distance
            let y = impactPoint.y + sin(particle.angle) * distance - 245 * local * local
            let fade = min(1, local * 7) * max(0, 1 - local / 0.92)
            let rect = NSRect(
                x: x - particle.size / 2,
                y: y - particle.size * particle.stretch / 2,
                width: particle.size,
                height: particle.size * particle.stretch
            )
            let drop = NSBezierPath(ovalIn: rect)
            (particle.size > 7 ? CaffeinatorTheme.amber : CaffeinatorTheme.caramel)
                .withAlphaComponent(fade * 0.85)
                .setFill()
            drop.fill()
        }

        if t < 0.50 {
            for index in 0..<7 {
                let angle = CGFloat(index) / 7 * .pi * 2
                let radius = 13 + ringProgress * (44 + CGFloat(index % 3) * 9)
                let size = 8 + CGFloat(index % 2) * 5
                let point = NSPoint(
                    x: impactPoint.x + cos(angle) * radius,
                    y: impactPoint.y + sin(angle) * radius * 0.42
                )
                let blob = NSBezierPath(ovalIn: NSRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size * 0.65))
                CaffeinatorTheme.espresso.withAlphaComponent((0.50 - t) * 1.7).setFill()
                blob.fill()
            }
        }
    }

    private func drawDeactivation(in context: CGContext) {
        let enter = CaffeinatorTheme.eased(min(progress / 0.28, 1))
        let fade = min(1, (1 - progress) / 0.13)
        let center = NSPoint(x: bounds.midX, y: bounds.midY + 52 - (1 - enter) * 18)

        drawCoffeeCup(
            in: context,
            center: center,
            scale: 1.02,
            active: false,
            steamPhase: progress * 6,
            alpha: enter * fade
        )

        drawToast(
            in: context,
            title: "CAFFEINE OFF",
            subtitle: "NORMAL SLEEP  •  RESTORED",
            accent: CaffeinatorTheme.cool,
            alpha: enter * fade,
            yOffset: 0
        )
    }

    private func drawToast(
        in context: CGContext,
        title: String,
        subtitle: String,
        accent: NSColor,
        alpha: CGFloat,
        yOffset: CGFloat
    ) {
        guard alpha > 0 else { return }
        context.saveGState()
        context.setAlpha(alpha)

        let width: CGFloat = 278
        let height: CGFloat = 78
        let rect = NSRect(
            x: bounds.midX - width / 2,
            y: impactPoint.y - 146 + yOffset,
            width: width,
            height: height
        )
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)
        shadow.shadowBlurRadius = 28
        shadow.shadowOffset = NSSize(width: 0, height: -8)
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        CaffeinatorTheme.midnight.withAlphaComponent(0.94).setFill()
        CaffeinatorTheme.roundedPath(rect, radius: 22).fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.10).setStroke()
        let border = CaffeinatorTheme.roundedPath(rect.insetBy(dx: 0.5, dy: 0.5), radius: 21.5)
        border.lineWidth = 1
        border.stroke()

        let dot = NSBezierPath(ovalIn: NSRect(x: rect.minX + 22, y: rect.midY + 4, width: 9, height: 9))
        accent.setFill()
        dot.fill()

        CaffeinatorTheme.drawText(
            title,
            in: NSRect(x: rect.minX + 42, y: rect.midY - 1, width: rect.width - 60, height: 22),
            font: .systemFont(ofSize: 15, weight: .semibold),
            color: CaffeinatorTheme.cream,
            kern: 0.4
        )
        CaffeinatorTheme.drawText(
            subtitle,
            in: NSRect(x: rect.minX + 42, y: rect.minY + 15, width: rect.width - 60, height: 18),
            font: .systemFont(ofSize: 10, weight: .medium),
            color: accent.withAlphaComponent(0.90),
            kern: 1.35
        )
        context.restoreGState()
    }
}

final class SplashOverlayController {
    private var panels: [OverlayPanel] = []

    func play(activating: Bool, from globalStartPoint: NSPoint?, sessionLabel: String?) {
        panels.forEach { $0.close() }
        panels.removeAll()

        let targetScreen = screen(containing: globalStartPoint ?? NSEvent.mouseLocation)
        let panel = OverlayPanel(screen: targetScreen)
        let defaultStart = NSPoint(x: targetScreen.frame.maxX - 52, y: targetScreen.frame.maxY - 34)
        let globalStart = globalStartPoint ?? defaultStart
        let localStart = NSPoint(
            x: globalStart.x - targetScreen.frame.minX,
            y: globalStart.y - targetScreen.frame.minY
        )

        let view = SplashOverlayView(
            frame: NSRect(origin: .zero, size: targetScreen.frame.size),
            activating: activating,
            startPoint: localStart,
            sessionLabel: sessionLabel
        ) { [weak self, weak panel] in
            panel?.orderOut(nil)
            panel?.close()
            self?.panels.removeAll { $0 === panel }
        }
        panel.contentView = view
        panels.append(panel)
        panel.orderFrontRegardless()
        view.start()
    }

    private func screen(containing point: NSPoint) -> NSScreen {
        NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main ?? NSScreen.screens[0]
    }
}
