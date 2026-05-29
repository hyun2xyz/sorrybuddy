import AppKit
import SwiftUI

@main
struct SorryBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state: AppState

    init() {
        _state = StateObject(wrappedValue: SharedAppState.state)
    }

    var body: some Scene {
        MenuBarExtra {
            SorryBuddyMenu(state: state)
                .onAppear {
                    state.refresh()
                }
        } label: {
            Text(state.isClosedLidModeActive ? "SB ON" : "SB")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct SorryBuddyMenu: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.isClosedLidModeActive ? "Closed-Lid Mode: ON" : "Closed-Lid Mode: OFF")
                .font(.headline)

            Text(state.lastMessage)
                .font(.caption)

            Divider()

            Button("닫힌 상태 작업 모드 켜기") {
                guard WarningDialog.confirmEnable() else {
                    return
                }

                state.enableClosedLidMode()
            }
            .disabled(state.isBusy || state.isClosedLidModeActive)

            Button("닫힌 상태 작업 모드 끄기") {
                state.disableClosedLidMode()
            }
            .disabled(state.isBusy || !state.isClosedLidModeActive)

            Button("상태 새로고침") {
                state.refresh()
            }
            .disabled(state.isBusy)

            Divider()

            Button("제어 창 열기") {
                (NSApplication.shared.delegate as? AppDelegate)?.showControlWindow()
            }

            Button("종료하기") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(10)
        .frame(width: 280, alignment: .leading)
    }
}
