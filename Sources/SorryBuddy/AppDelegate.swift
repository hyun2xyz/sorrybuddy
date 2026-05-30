import AppKit
import SorryBuddyCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var controlWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var statusMenu = NSMenu()
    private var safetyTimer: Timer?
    private var lidTimer: Timer?
    private var isCheckingForUpdates = false
    private lazy var updateChecker = GitHubUpdateChecker(currentVersion: Self.currentVersion)

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

        let updates = NSMenuItem(
            title: isCheckingForUpdates ? "업데이트 확인 중..." : "업데이트 확인...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updates.target = self
        updates.isEnabled = !isCheckingForUpdates
        statusMenu.addItem(updates)

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

    @objc private func checkForUpdates() {
        guard !isCheckingForUpdates else {
            return
        }

        isCheckingForUpdates = true
        rebuildStatusMenu()

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                let outcome = try await updateChecker.checkForUpdate()
                presentUpdateOutcome(outcome)
            } catch {
                presentUpdateFailure(error)
            }

            isCheckingForUpdates = false
            rebuildStatusMenu()
        }
    }

    @objc private func openControlWindow() {
        showControlWindow()
    }

    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }

    private func presentUpdateOutcome(_ outcome: UpdateCheckOutcome) {
        switch outcome {
        case .upToDate(let version):
            let alert = NSAlert()
            alert.messageText = "최신 버전입니다."
            alert.informativeText = "SorryBuddy \(version)을 사용 중입니다."
            alert.addButton(withTitle: "확인")
            alert.runModal()
        case .updateAvailable(let update):
            let alert = NSAlert()
            alert.messageText = "새 버전이 있습니다."
            alert.informativeText = "SorryBuddy \(update.latestVersion)을 다운로드할 수 있습니다."
            alert.addButton(withTitle: "다운로드 열기")
            alert.addButton(withTitle: "나중에")

            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(update.downloadURL ?? update.releaseURL)
            }
        }
    }

    private func presentUpdateFailure(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "업데이트 확인 실패"
        alert.informativeText = "GitHub 릴리즈를 확인하지 못했습니다.\n\(error.localizedDescription)"
        alert.addButton(withTitle: "릴리즈 페이지 열기")
        alert.addButton(withTitle: "닫기")

        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/latest") {
            NSWorkspace.shared.open(url)
        }
    }

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.1"
    }
}
