import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: create-dmg-background.swift <output.png>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 680, height: 360)
let image = NSImage(size: size)

image.lockFocus()

NSColor(calibratedRed: 0.93, green: 0.93, blue: 0.93, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

let arrow = NSBezierPath()
arrow.lineWidth = 3
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.setLineDash([8, 6], count: 2, phase: 0)

let centerY: CGFloat = 190
arrow.move(to: NSPoint(x: 300, y: centerY))
arrow.line(to: NSPoint(x: 390, y: centerY))
arrow.move(to: NSPoint(x: 360, y: centerY + 45))
arrow.line(to: NSPoint(x: 405, y: centerY))
arrow.line(to: NSPoint(x: 360, y: centerY - 45))
arrow.move(to: NSPoint(x: 300, y: centerY + 22))
arrow.line(to: NSPoint(x: 300, y: centerY - 22))
arrow.move(to: NSPoint(x: 300, y: centerY + 22))
arrow.line(to: NSPoint(x: 330, y: centerY + 22))
arrow.move(to: NSPoint(x: 300, y: centerY - 22))
arrow.line(to: NSPoint(x: 330, y: centerY - 22))

NSColor(calibratedWhite: 0.42, alpha: 1).setStroke()
arrow.stroke()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render background PNG\n", stderr)
    exit(1)
}

try png.write(to: outputURL)
