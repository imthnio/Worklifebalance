import AppKit

/// Cat head outline in an 18×18 pt box (y points up)
private func catHeadPath() -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: 2.6, y: 8.2))
    p.line(to: NSPoint(x: 3.2, y: 15.8))      // left ear tip
    p.line(to: NSPoint(x: 7.0, y: 12.6))
    p.curve(to: NSPoint(x: 11.0, y: 12.6),
            controlPoint1: NSPoint(x: 8.2, y: 13.1), controlPoint2: NSPoint(x: 9.8, y: 13.1))
    p.line(to: NSPoint(x: 14.8, y: 15.8))     // right ear tip
    p.line(to: NSPoint(x: 15.4, y: 8.2))
    p.curve(to: NSPoint(x: 9.0, y: 2.4),
            controlPoint1: NSPoint(x: 15.4, y: 4.6), controlPoint2: NSPoint(x: 12.6, y: 2.4))
    p.curve(to: NSPoint(x: 2.6, y: 8.2),
            controlPoint1: NSPoint(x: 5.4, y: 2.4), controlPoint2: NSPoint(x: 2.6, y: 4.6))
    p.close()
    p.lineJoinStyle = .round
    return p
}

private let eyes = [NSRect(x: 5.6, y: 7.0, width: 1.9, height: 2.3),
                    NSRect(x: 10.5, y: 7.0, width: 1.9, height: 2.3)]

/// Menu bar icon: an outlined cat head when idle, a filled one while focusing
func catHeadImage(filled: Bool) -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
        NSColor.black.set()
        let head = catHeadPath()
        if filled {
            head.fill()
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            eyes.forEach { NSBezierPath(ovalIn: $0).fill() }
        } else {
            head.lineWidth = 1.5
            head.stroke()
            eyes.forEach { NSBezierPath(ovalIn: $0).fill() }
        }
        return true
    }
    image.isTemplate = true
    return image
}
