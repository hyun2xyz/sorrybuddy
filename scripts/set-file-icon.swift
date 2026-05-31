import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: set-file-icon.swift <icon.icns> <target-file>\n", stderr)
    exit(2)
}

let iconPath = CommandLine.arguments[1]
let targetPath = CommandLine.arguments[2]

guard FileManager.default.fileExists(atPath: targetPath) else {
    fputs("Target file does not exist: \(targetPath)\n", stderr)
    exit(1)
}

guard let icon = NSImage(contentsOfFile: iconPath) else {
    fputs("Could not load icon: \(iconPath)\n", stderr)
    exit(1)
}

if !NSWorkspace.shared.setIcon(icon, forFile: targetPath, options: []) {
    fputs("Failed to set custom icon for: \(targetPath)\n", stderr)
    exit(1)
}
