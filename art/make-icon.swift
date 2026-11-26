// Renders the Dinky Cal app icon at 1024×1024: `swift art/make-icon.swift out.png`
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let hasFeet = true
let hasHat = true

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS icon grid: 824pt rounded-rect body centered, with a soft drop shadow.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = color(0x000000, 0.28)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
color(0xFFC94D).setFill()
bodyPath.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: color(0xFFD86B), ending: color(0xFFB238))!.draw(in: bodyPath, angle: -90)

// The dinky calendar page.
let page = hasHat ? NSRect(x: 292, y: hasFeet ? 260 : 220, width: 440, height: 400) : NSRect(x: 292, y: 318, width: 440, height: 420)
let pagePath = NSBezierPath(roundedRect: page, xRadius: 64, yRadius: 64)

// Feet first so the page overlaps them.
color(0x3B2A1A).setFill()
for x in (hasFeet ? [page.midX - 110, page.midX + 42] : []) {
    NSBezierPath(roundedRect: NSRect(x: x, y: page.minY - 64, width: 68, height: 92), xRadius: 30, yRadius: 30).fill()
    NSBezierPath(roundedRect: NSRect(x: x - (x < page.midX ? 26 : 0), y: page.minY - 70, width: 94, height: 40), xRadius: 20, yRadius: 20).fill()
}

NSGraphicsContext.saveGraphicsState()
let pageShadow = NSShadow()
pageShadow.shadowColor = color(0x7A4A00, 0.35)
pageShadow.shadowBlurRadius = 18
pageShadow.shadowOffset = NSSize(width: 0, height: -8)
pageShadow.set()
color(0xFFFFFF).setFill()
pagePath.fill()
NSGraphicsContext.restoreGraphicsState()

// Header band.
NSGraphicsContext.saveGraphicsState()
pagePath.addClip()
(hasHat ? color(0x2F6FEB) : color(0xE5484D)).setFill()
NSRect(x: page.minX, y: page.maxY - 118, width: page.width, height: 118).fill()
NSGraphicsContext.restoreGraphicsState()

// Binder rings.
color(0x3B2A1A).setFill()
for x in (hasHat ? [] : [page.minX + 112, page.maxX - 112]) {
    NSBezierPath(roundedRect: NSRect(x: x - 17, y: page.maxY - 40, width: 34, height: 84), xRadius: 17, yRadius: 17).fill()
}


// A garden-gnome hat, tipped to one side.
if hasHat {
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: page.midX + 4, yBy: page.maxY - 26)
    t.rotate(byDegrees: -9)
    t.concat()
    // Tall cone whose tip flops over to the right.
    let cone = NSBezierPath()
    cone.move(to: NSPoint(x: -150, y: 0))
    cone.curve(to: NSPoint(x: 10, y: 232), controlPoint1: NSPoint(x: -110, y: 92), controlPoint2: NSPoint(x: -52, y: 190))
    cone.curve(to: NSPoint(x: 112, y: 214), controlPoint1: NSPoint(x: 52, y: 262), controlPoint2: NSPoint(x: 96, y: 250))
    cone.curve(to: NSPoint(x: 66, y: 176), controlPoint1: NSPoint(x: 118, y: 196), controlPoint2: NSPoint(x: 92, y: 182))
    cone.curve(to: NSPoint(x: 150, y: 0), controlPoint1: NSPoint(x: 104, y: 120), controlPoint2: NSPoint(x: 134, y: 60))
    cone.close()
    let hatShadow = NSShadow()
    hatShadow.shadowColor = color(0x7A1A1A, 0.35)
    hatShadow.shadowBlurRadius = 14
    hatShadow.shadowOffset = NSSize(width: 0, height: -6)
    hatShadow.set()
    NSGradient(starting: color(0xF2605F), ending: color(0xC9303A))!.draw(in: cone, angle: -20)
    NSShadow().set()
    // Soft highlight down the left side of the cone.
    NSGraphicsContext.saveGraphicsState()
    cone.addClip()
    let shine = NSBezierPath()
    shine.move(to: NSPoint(x: -150, y: 0))
    shine.curve(to: NSPoint(x: 10, y: 232), controlPoint1: NSPoint(x: -110, y: 92), controlPoint2: NSPoint(x: -52, y: 190))
    shine.curve(to: NSPoint(x: -70, y: 0), controlPoint1: NSPoint(x: -40, y: 160), controlPoint2: NSPoint(x: -66, y: 80))
    shine.close()
    color(0xFFFFFF, 0.16).setFill()
    shine.fill()
    NSGraphicsContext.restoreGraphicsState()
    // brim
    color(0xA8262D).setFill()
    NSBezierPath(roundedRect: NSRect(x: -165, y: -18, width: 330, height: 40), xRadius: 20, yRadius: 20).fill()
    NSGraphicsContext.restoreGraphicsState()
}

// Heatmap dots: 4 columns × 3 rows at varying intensity.
let levels: [[CGFloat]] = [[0.25, 1.0, 0.0, 0.55], [0.55, 0.25, 0.8, 0.0], [0.0, 0.8, 0.25, 1.0]]
let gridLeft = page.minX + 82, gridTop = page.maxY - 178
for (r, row) in levels.enumerated() {
    for (c, level) in row.enumerated() {
        let center = NSPoint(x: gridLeft + CGFloat(c) * 92, y: gridTop - CGFloat(r) * 82)
        let d: CGFloat = 46
        let dot = NSBezierPath(ovalIn: NSRect(x: center.x - d / 2, y: center.y - d / 2, width: d, height: d))
        if level == 0 {
            color(0x2F6FEB, 0.12).setFill()
        } else {
            color(0x2F6FEB, level).setFill()
        }
        dot.fill()
    }
}

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
