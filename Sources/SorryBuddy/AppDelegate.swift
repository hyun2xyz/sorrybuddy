import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var controlWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var statusMenu = NSMenu()
    private var safetyTimer: Timer?
    private var lidTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        showControlWindow()
        safetyTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor [weak self] in
                SharedAppState.state.safetyTick()
                self?.updateStatusIcon()
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

    func menuWillOpen(_ menu: NSMenu) {
        SharedAppState.state.refresh()
        rebuildStatusMenu()
        updateStatusIcon()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = "xyz.hyun2.sorrybuddy.statusitem"
        item.button?.imagePosition = .imageOnly
        item.button?.imageScaling = .scaleProportionallyDown
        item.button?.contentTintColor = .labelColor
        item.button?.toolTip = "SorryBuddy"
        item.button?.setAccessibilityLabel("SorryBuddy")
        item.menu = statusMenu
        statusItem = item

        statusMenu.delegate = self
        SharedAppState.state.refresh()
        rebuildStatusMenu()
        updateStatusIcon()
    }

    private func rebuildStatusMenu() {
        let state = SharedAppState.state
        statusMenu.removeAllItems()

        let statusTitle = state.isClosedLidModeActive ? "Closed-Lid Mode: ON" : "Closed-Lid Mode: OFF"
        let status = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        status.isEnabled = false
        statusMenu.addItem(status)

        let message = NSMenuItem(title: state.lastMessage, action: nil, keyEquivalent: "")
        message.isEnabled = false
        statusMenu.addItem(message)

        statusMenu.addItem(.separator())

        let enable = NSMenuItem(title: "닫힌 상태 작업 모드 켜기", action: #selector(enableClosedLidMode), keyEquivalent: "")
        enable.target = self
        enable.isEnabled = !state.isBusy && !state.isClosedLidModeActive
        statusMenu.addItem(enable)

        let disable = NSMenuItem(title: "닫힌 상태 작업 모드 끄기", action: #selector(disableClosedLidMode), keyEquivalent: "")
        disable.target = self
        disable.isEnabled = !state.isBusy && state.isClosedLidModeActive
        statusMenu.addItem(disable)

        let refresh = NSMenuItem(title: "상태 새로고침", action: #selector(refreshStatus), keyEquivalent: "")
        refresh.target = self
        refresh.isEnabled = !state.isBusy
        statusMenu.addItem(refresh)

        statusMenu.addItem(.separator())

        let openWindow = NSMenuItem(title: "제어 창 열기", action: #selector(openControlWindow), keyEquivalent: "")
        openWindow.target = self
        statusMenu.addItem(openWindow)

        let quit = NSMenuItem(title: "종료하기", action: #selector(quitApplication), keyEquivalent: "")
        quit.target = self
        statusMenu.addItem(quit)
    }

    private func updateStatusIcon() {
        statusItem?.button?.image = MenuBarIconFactory.image(isActive: SharedAppState.state.isClosedLidModeActive)
    }

    @objc private func enableClosedLidMode() {
        guard WarningDialog.confirmEnable() else {
            return
        }

        SharedAppState.state.enableClosedLidMode()
        rebuildStatusMenu()
        updateStatusIcon()
    }

    @objc private func disableClosedLidMode() {
        SharedAppState.state.disableClosedLidMode()
        rebuildStatusMenu()
        updateStatusIcon()
    }

    @objc private func refreshStatus() {
        SharedAppState.state.refresh()
        rebuildStatusMenu()
        updateStatusIcon()
    }

    @objc private func openControlWindow() {
        showControlWindow()
    }

    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
}
