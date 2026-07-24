import AppKit

guard CommandLine.arguments.count == 4 else {
    fputs("usage: social-card-composer ICON DASHBOARD OUTPUT\n", stderr)
    exit(2)
}

guard let icon = NSImage(contentsOfFile: CommandLine.arguments[1]),
      let dashboard = NSImage(contentsOfFile: CommandLine.arguments[2]) else {
    fputs("could not read social card inputs\n", stderr)
    exit(2)
}

let width = 1280
let height = 640
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("could not allocate social card bitmap\n", stderr)
    exit(2)
}

func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func text(
    _ value: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    kern: CGFloat = 0
) {
    let style = NSMutableParagraphStyle()
    style.alignment = .left
    (value as NSString).draw(in: rect, withAttributes: [
        .font: font,
        .foregroundColor: color,
        .kern: kern,
        .paragraphStyle: style
    ])
}

func badge(_ label: String, x: CGFloat, width: CGFloat) {
    let rect = NSRect(x: x, y: 76, width: width, height: 38)
    NSColor.white.withAlphaComponent(0.055).setFill()
    rounded(rect, 19).fill()
    NSColor.white.withAlphaComponent(0.13).setStroke()
    rounded(rect.insetBy(dx: 0.5, dy: 0.5), 18.5).stroke()
    text(
        label,
        in: NSRect(x: rect.minX + 15, y: rect.minY + 10, width: rect.width - 30, height: 19),
        font: .systemFont(ofSize: 13, weight: .semibold),
        color: NSColor(calibratedRed: 0.88, green: 0.90, blue: 0.94, alpha: 1),
        kern: 0.15
    )
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
graphics.imageInterpolation = .high

let canvas = NSRect(x: 0, y: 0, width: width, height: height)
let background = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.020, green: 0.030, blue: 0.065, alpha: 1), 0),
    (NSColor(calibratedRed: 0.045, green: 0.065, blue: 0.115, alpha: 1), 0.55),
    (NSColor(calibratedRed: 0.025, green: 0.040, blue: 0.080, alpha: 1), 1)
)!
background.draw(in: canvas, angle: 0)

let amber = NSColor(calibratedRed: 1.0, green: 0.58, blue: 0.12, alpha: 1)
let mint = NSColor(calibratedRed: 0.35, green: 0.94, blue: 0.67, alpha: 1)
let cream = NSColor(calibratedRed: 1.0, green: 0.96, blue: 0.86, alpha: 1)

let halo = NSGradient(colors: [
    amber.withAlphaComponent(0.19),
    amber.withAlphaComponent(0)
])!
halo.draw(
    in: NSBezierPath(ovalIn: NSRect(x: -70, y: 120, width: 650, height: 650)),
    relativeCenterPosition: NSPoint(x: -0.12, y: 0.05)
)

for index in 0..<18 {
    let x = CGFloat(37 + ((index * 97) % 760))
    let y = CGFloat(38 + ((index * 151) % 560))
    let size = CGFloat(index % 3 + 1)
    NSColor.white.withAlphaComponent(index % 2 == 0 ? 0.08 : 0.04).setFill()
    NSBezierPath(ovalIn: NSRect(x: x, y: y, width: size, height: size)).fill()
}

let iconRect = NSRect(x: 72, y: 358, width: 162, height: 162)
let iconShadow = NSShadow()
iconShadow.shadowColor = NSColor.black.withAlphaComponent(0.42)
iconShadow.shadowBlurRadius = 34
iconShadow.shadowOffset = NSSize(width: 0, height: -14)
NSGraphicsContext.saveGraphicsState()
iconShadow.set()
icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()

text(
    "CAFFEINATOR",
    in: NSRect(x: 72, y: 276, width: 720, height: 78),
    font: .systemFont(ofSize: 62, weight: .heavy),
    color: cream,
    kern: 1.6
)
text(
    "Remote-ready Mac. One click.",
    in: NSRect(x: 76, y: 224, width: 660, height: 44),
    font: .systemFont(ofSize: 29, weight: .semibold),
    color: amber
)
text(
    "A tiny native menu-bar app that keeps your Mac awake\nfor remote work—without living in Terminal.",
    in: NSRect(x: 76, y: 140, width: 650, height: 72),
    font: .systemFont(ofSize: 20, weight: .regular),
    color: NSColor.white.withAlphaComponent(0.67)
)

badge("Native macOS", x: 76, width: 134)
badge("Open source", x: 222, width: 130)
badge("No tracking", x: 364, width: 120)

let readyRect = NSRect(x: 510, y: 76, width: 153, height: 38)
mint.withAlphaComponent(0.11).setFill()
rounded(readyRect, 19).fill()
mint.withAlphaComponent(0.30).setStroke()
rounded(readyRect.insetBy(dx: 0.5, dy: 0.5), 18.5).stroke()
mint.setFill()
NSBezierPath(ovalIn: NSRect(x: readyRect.minX + 15, y: readyRect.midY - 4, width: 8, height: 8)).fill()
text(
    "REMOTE READY",
    in: NSRect(x: readyRect.minX + 32, y: readyRect.minY + 10, width: 108, height: 18),
    font: .systemFont(ofSize: 11.5, weight: .bold),
    color: mint,
    kern: 0.65
)

let dashboardHeight: CGFloat = 514
let dashboardWidth = dashboardHeight * (dashboard.size.width / dashboard.size.height)
let dashboardRect = NSRect(
    x: 1280 - dashboardWidth - 86,
    y: (640 - dashboardHeight) / 2,
    width: dashboardWidth,
    height: dashboardHeight
)
let dashboardShadow = NSShadow()
dashboardShadow.shadowColor = NSColor.black.withAlphaComponent(0.58)
dashboardShadow.shadowBlurRadius = 50
dashboardShadow.shadowOffset = NSSize(width: 0, height: -18)
NSGraphicsContext.saveGraphicsState()
dashboardShadow.set()
dashboard.draw(in: dashboardRect, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()

let divider = NSBezierPath()
divider.move(to: NSPoint(x: 800, y: 86))
divider.line(to: NSPoint(x: 800, y: 554))
NSColor.white.withAlphaComponent(0.07).setStroke()
divider.lineWidth = 1
divider.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("could not encode social card\n", stderr)
    exit(2)
}
do {
    try png.write(to: URL(fileURLWithPath: CommandLine.arguments[3]), options: .atomic)
} catch {
    fputs("could not write social card: \(error)\n", stderr)
    exit(2)
}
