import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controlWindow: NSWindow?
    private var safetyTimer: Timer?
    private var lidTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        showControlWindow()
        safetyTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                SharedAppState.state.safetyTick()
            }
        }
        lidTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in
                SharedAppState.state.lidTick()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        safetyTimer?.invalidate()
        lidTimer?.invalidate()
        SharedAppState.state.restoreBeforeQuit()
    }

    @MainActor
    func showControlWindow() {
        if controlWindow == nil {
            let controller = NSHostingController(rootView: ContentView(state: SharedAppState.state))
            let window = NSWindow(contentViewController: controller)
            window.title = "SorryBuddy"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            controlWindow = window
        }

        controlWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
