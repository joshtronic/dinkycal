import AppKit

enum IconStyle: String, CaseIterable {
    case date, glyph
}

enum StatusIcon {
    /// Template image for the menu bar: a small calendar page, optionally showing the day number.
    static func image(day: Int?, style: IconStyle) -> NSImage {
        let size = NSSize(width: 19, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            let page = rect.insetBy(dx: 1.5, dy: 0.75)
            let path = NSBezierPath(roundedRect: page, xRadius: 3, yRadius: 3)
            NSColor.black.setStroke()
            path.lineWidth = 1.3
            path.stroke()

            // Header band across the top of the page.
            NSGraphicsContext.saveGraphicsState()
            path.addClip()
            NSColor.black.setFill()
            NSRect(x: page.minX, y: page.maxY - 4, width: page.width, height: 4).fill()
            NSGraphicsContext.restoreGraphicsState()

            let body = NSRect(x: page.minX, y: page.minY, width: page.width, height: page.height - 4)
            if style == .date, let day {
                let text = "\(day)" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .bold),
                    .foregroundColor: NSColor.black,
                ]
                let textSize = text.size(withAttributes: attrs)
                text.draw(at: NSPoint(x: body.midX - textSize.width / 2,
                                      y: body.midY - textSize.height / 2 + 0.25),
                          withAttributes: attrs)
            } else {
                // Three tiny dots: the "dinky" heatmap.
                NSColor.black.setFill()
                for i in 0..<3 {
                    let x = body.midX - 4.5 + CGFloat(i) * 3.5
                    NSBezierPath(ovalIn: NSRect(x: x, y: body.midY - 1, width: 2, height: 2)).fill()
                }
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Dinky Cal"
        return image
    }
}
