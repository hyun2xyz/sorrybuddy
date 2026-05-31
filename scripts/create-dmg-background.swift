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
arrow.lineWidth = 2.8
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.setLineDash([7, 6], count: 2, phase: 0)

let centerY: CGFloat = 194
let tailX: CGFloat = 288
let shaftX: CGFloat = 344
let tipX: CGFloat = 410
let shaftHalfHeight: CGFloat = 24
let headHalfHeight: CGFloat = 58

arrow.move(to: NSPoint(x: tailX, y: centerY + shaftHalfHeight))
arrow.line(to: NSPoint(x: shaftX, y: centerY + shaftHalfHeight))
arrow.line(to: NSPoint(x: shaftX, y: centerY + headHalfHeight))
arrow.line(to: NSPoint(x: tipX, y: centerY))
arrow.line(to: NSPoint(x: shaftX, y: centerY - headHalfHeight))
arrow.line(to: NSPoint(x: shaftX, y: centerY - shaftHalfHeight))
arrow.line(to: NSPoint(x: tailX, y: centerY - shaftHalfHeight))
arrow.close()

NSColor(calibratedWhite: 0.46, alpha: 1).setStroke()
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
