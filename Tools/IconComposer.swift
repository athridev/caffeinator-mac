import AppKit

guard CommandLine.arguments.count == 3 else {
    fputs("usage: icon-composer INPUT OUTPUT\n", stderr)
    exit(2)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]
guard let source = NSImage(contentsOfFile: inputPath) else {
    fputs("could not read icon source\n", stderr)
    exit(2)
}

let pixels = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("could not allocate icon bitmap\n", stderr)
    exit(2)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
graphics.imageInterpolation = .high

let canvas = NSRect(x: 0, y: 0, width: pixels, height: pixels)
NSColor.clear.setFill()
canvas.fill(using: .copy)

let iconRect = NSRect(x: 62, y: 66, width: 900, height: 900)
let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 205, yRadius: 205)

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
shadow.shadowBlurRadius = 42
shadow.shadowOffset = NSSize(width: 0, height: -18)
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor.black.setFill()
iconPath.fill()
NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.saveGraphicsState()
iconPath.addClip()
source.draw(
    in: iconRect,
    from: NSRect(origin: .zero, size: source.size),
    operation: .sourceOver,
    fraction: 1,
    respectFlipped: true,
    hints: [.interpolation: NSImageInterpolation.high]
)

let sheen = NSGradient(colorsAndLocations:
    (NSColor.white.withAlphaComponent(0.15), 0),
    (NSColor.white.withAlphaComponent(0.00), 0.40),
    (NSColor.black.withAlphaComponent(0.10), 1)
)!
sheen.draw(in: iconPath, angle: -90)
NSGraphicsContext.restoreGraphicsState()

NSColor.white.withAlphaComponent(0.16).setStroke()
let highlight = NSBezierPath(roundedRect: iconRect.insetBy(dx: 1.5, dy: 1.5), xRadius: 203.5, yRadius: 203.5)
highlight.lineWidth = 3
highlight.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("could not encode icon\n", stderr)
    exit(2)
}
do {
    try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
} catch {
    fputs("could not write icon: \(error)\n", stderr)
    exit(2)
}
