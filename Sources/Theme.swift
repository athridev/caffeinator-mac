import AppKit

enum CaffeinatorTheme {
    static let midnight = NSColor(calibratedRed: 0.035, green: 0.051, blue: 0.094, alpha: 1)
    static let panelTop = NSColor(calibratedRed: 0.075, green: 0.094, blue: 0.145, alpha: 0.985)
    static let panelBottom = NSColor(calibratedRed: 0.026, green: 0.036, blue: 0.070, alpha: 0.995)
    static let cream = NSColor(calibratedRed: 1.0, green: 0.955, blue: 0.830, alpha: 1)
    static let mutedCream = NSColor(calibratedRed: 0.70, green: 0.72, blue: 0.77, alpha: 1)
    static let amber = NSColor(calibratedRed: 1.0, green: 0.57, blue: 0.12, alpha: 1)
    static let brightAmber = NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.23, alpha: 1)
    static let espresso = NSColor(calibratedRed: 0.27, green: 0.095, blue: 0.035, alpha: 1)
    static let caramel = NSColor(calibratedRed: 0.72, green: 0.28, blue: 0.055, alpha: 1)
    static let coral = NSColor(calibratedRed: 1.0, green: 0.36, blue: 0.25, alpha: 1)
    static let mint = NSColor(calibratedRed: 0.35, green: 0.94, blue: 0.67, alpha: 1)
    static let cool = NSColor(calibratedRed: 0.48, green: 0.67, blue: 0.89, alpha: 1)

    static func roundedPath(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    }

    static func drawText(
        _ text: String,
        in rect: NSRect,
        font: NSFont,
        color: NSColor,
        alignment: NSTextAlignment = .left,
        kern: CGFloat = 0,
        lineHeight: CGFloat? = nil
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        if let lineHeight {
            paragraph.minimumLineHeight = lineHeight
            paragraph.maximumLineHeight = lineHeight
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: kern
        ]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }

    static func eased(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return 1 - pow(1 - t, 3)
    }

    static func smoothstep(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

func pointOnQuadratic(_ start: NSPoint, _ control: NSPoint, _ end: NSPoint, _ t: CGFloat) -> NSPoint {
    let oneMinus = 1 - t
    return NSPoint(
        x: oneMinus * oneMinus * start.x + 2 * oneMinus * t * control.x + t * t * end.x,
        y: oneMinus * oneMinus * start.y + 2 * oneMinus * t * control.y + t * t * end.y
    )
}

func drawCoffeeCup(
    in context: CGContext,
    center: NSPoint,
    scale: CGFloat,
    active: Bool,
    rotation: CGFloat = 0,
    steamPhase: CGFloat = 0,
    alpha: CGFloat = 1
) {
    context.saveGState()
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: rotation)
    context.scaleBy(x: scale, y: scale)
    context.setAlpha(alpha)

    let cupRect = NSRect(x: -31, y: -24, width: 58, height: 42)
    let cup = NSBezierPath()
    cup.move(to: NSPoint(x: -29, y: 15))
    cup.curve(to: NSPoint(x: -21, y: -22), controlPoint1: NSPoint(x: -28, y: -2), controlPoint2: NSPoint(x: -27, y: -18))
    cup.curve(to: NSPoint(x: 17, y: -22), controlPoint1: NSPoint(x: -10, y: -27), controlPoint2: NSPoint(x: 10, y: -27))
    cup.curve(to: NSPoint(x: 25, y: 15), controlPoint1: NSPoint(x: 22, y: -13), controlPoint2: NSPoint(x: 25, y: 2))
    cup.close()

    let cupGradient = NSGradient(colors: [
        NSColor(calibratedWhite: 1, alpha: 1),
        CaffeinatorTheme.cream,
        NSColor(calibratedRed: 0.70, green: 0.62, blue: 0.50, alpha: 1)
    ])!
    cupGradient.draw(in: cup, angle: -76)

    NSColor.white.withAlphaComponent(0.48).setStroke()
    cup.lineWidth = 1.2
    cup.stroke()

    let rimOuter = NSBezierPath(ovalIn: NSRect(x: -30, y: 9, width: 56, height: 16))
    CaffeinatorTheme.cream.setFill()
    rimOuter.fill()

    let coffeeRect = NSRect(x: -26, y: 11.5, width: 48, height: 10.5)
    let coffee = NSBezierPath(ovalIn: coffeeRect)
    let coffeeGradient = NSGradient(colors: [
        active ? CaffeinatorTheme.brightAmber : CaffeinatorTheme.caramel,
        CaffeinatorTheme.espresso
    ])!
    coffeeGradient.draw(in: coffee, angle: 90)

    let shine = NSBezierPath()
    shine.move(to: NSPoint(x: -19, y: 7))
    shine.curve(to: NSPoint(x: -15, y: -13), controlPoint1: NSPoint(x: -19, y: -2), controlPoint2: NSPoint(x: -18, y: -10))
    NSColor.white.withAlphaComponent(0.32).setStroke()
    shine.lineWidth = 3.1
    shine.lineCapStyle = .round
    shine.stroke()

    let handle = NSBezierPath()
    handle.move(to: NSPoint(x: 23, y: 9))
    handle.curve(to: NSPoint(x: 40, y: -3), controlPoint1: NSPoint(x: 42, y: 11), controlPoint2: NSPoint(x: 44, y: 1))
    handle.curve(to: NSPoint(x: 24, y: -12), controlPoint1: NSPoint(x: 37, y: -13), controlPoint2: NSPoint(x: 29, y: -14))
    CaffeinatorTheme.cream.setStroke()
    handle.lineWidth = 7
    handle.lineCapStyle = .round
    handle.stroke()

    NSColor.white.withAlphaComponent(0.28).setStroke()
    handle.lineWidth = 1.2
    handle.stroke()

    if active {
        let glow = NSBezierPath(ovalIn: NSRect(x: -10, y: 12.5, width: 20, height: 6))
        CaffeinatorTheme.amber.withAlphaComponent(0.52).setFill()
        glow.fill()
    }

    if steamPhase >= 0 {
        for index in 0..<2 {
            let offset = CGFloat(index) * 13 - 7
            let phase = steamPhase + CGFloat(index) * 0.7
            let steam = NSBezierPath()
            steam.move(to: NSPoint(x: offset, y: 28))
            steam.curve(
                to: NSPoint(x: offset + sin(phase) * 3, y: 56),
                controlPoint1: NSPoint(x: offset - 8, y: 36),
                controlPoint2: NSPoint(x: offset + 9, y: 46)
            )
            (active ? CaffeinatorTheme.amber : CaffeinatorTheme.cool)
                .withAlphaComponent(active ? 0.70 : 0.42)
                .setStroke()
            steam.lineWidth = active ? 3.2 : 2.3
            steam.lineCapStyle = .round
            steam.stroke()
        }
    }

    _ = cupRect
    context.restoreGState()
}
