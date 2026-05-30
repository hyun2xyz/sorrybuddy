import AppKit

enum MenuBarIconFactory {
    static func image(isActive: Bool) -> NSImage {
        if let url = Bundle.main.url(forResource: "SorryBuddyMenuBar", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            image.size = NSSize(width: 22, height: 22)
            image.isTemplate = false
            image.accessibilityDescription = isActive ? "SorryBuddy on" : "SorryBuddy"
            return image
        }

        let size = NSSize(width: 21, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            drawSproutIcon(in: rect, isActive: isActive)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = isActive ? "SorryBuddy on" : "SorryBuddy"
        return image
    }

    private static func drawSproutIcon(in rect: NSRect, isActive: Bool) {
        let scale = min(rect.width / 21, rect.height / 18)
        let xOffset = rect.midX - (21 * scale / 2)
        let yOffset = rect.midY - (18 * scale / 2)

        func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(x: xOffset + x * scale, y: yOffset + y * scale)
        }

        NSColor.black.setStroke()
        NSColor.black.setFill()

        let lineWidth: CGFloat = (isActive ? 2.2 : 2.0) * scale
        let sprout = NSBezierPath()
        sprout.lineWidth = lineWidth
        sprout.lineCapStyle = .round
        sprout.lineJoinStyle = .round

        sprout.move(to: point(10.5, 9.0))
        sprout.curve(
            to: point(4.2, 12.0),
            controlPoint1: point(8.1, 9.2),
            controlPoint2: point(4.8, 9.8)
        )
        sprout.curve(
            to: point(10.5, 9.0),
            controlPoint1: point(5.0, 16.1),
            controlPoint2: point(9.0, 15.1)
        )

        sprout.move(to: point(10.5, 9.0))
        sprout.curve(
            to: point(16.8, 12.0),
            controlPoint1: point(12.9, 9.2),
            controlPoint2: point(16.2, 9.8)
        )
        sprout.curve(
            to: point(10.5, 9.0),
            controlPoint1: point(16.0, 16.1),
            controlPoint2: point(12.0, 15.1)
        )

        sprout.move(to: point(10.5, 8.9))
        sprout.line(to: point(10.5, 6.3))
        sprout.stroke()

        let eyeSize = (isActive ? 3.2 : 3.0) * scale
        NSBezierPath(ovalIn: NSRect(x: point(6.5, 2.4).x, y: point(0, 2.4).y, width: eyeSize, height: eyeSize)).fill()
        NSBezierPath(ovalIn: NSRect(x: point(12.7, 2.4).x, y: point(0, 2.4).y, width: eyeSize, height: eyeSize)).fill()
    }
}
