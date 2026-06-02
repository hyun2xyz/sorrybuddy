import Foundation
import SorryBuddyCore

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isClosedLidModeActive = false
    @Published private(set) var batteryStatus: BatteryStatus?
    @Published private(set) var lastMessage = "상태를 확인하는 중입니다."
    @Published private(set) var isBusy = false

    private let service: PowerPolicyService
    private let lidBrightnessCoordinator: LidBrightnessCoordinator
    private let workModeAssertions: WorkModeAssertionControlling
    private var enabledByThisRun = false
    private var warnedAtTwelvePercent = false

    init(
        service: PowerPolicyService = PowerPolicyService(),
        lidBrightnessCoordinator: LidBrightnessCoordinator = LidBrightnessCoordinator(),
        workModeAssertions: WorkModeAssertionControlling = WorkModeAssertionController()
    ) {
        self.service = service
        self.lidBrightnessCoordinator = lidBrightnessCoordinator
        self.workModeAssertions = workModeAssertions
    }

    func refresh() {
        do {
            let settings = try service.currentPowerSettings()
            let battery = try service.currentBatteryStatus()
            isClosedLidModeActive = settings.closedLidSleepDisabled
            batteryStatus = battery
            syncWorkModeAssertions(isActive: settings.closedLidSleepDisabled)
            lastMessage = statusMessage(for: battery)
        } catch {
            lastMessage = "상태 확인 실패: \(error.localizedDescription)"
        }
    }

    func enableClosedLidMode() {
        perform("닫힌 상태 작업 모드를 켰습니다.") {
            try service.enableClosedLidMode()
            do {
                try workModeAssertions.activate()
                enabledByThisRun = true
            } catch {
                try? service.disableClosedLidMode()
                throw error
            }
        }
    }

    func disableClosedLidMode() {
        perform("닫힌 상태 작업 모드를 껐습니다.") {
            try service.disableClosedLidMode()
            workModeAssertions.deactivate()
            try lidBrightnessCoordinator.tick(isClosedLidModeActive: false)
            enabledByThisRun = false
            warnedAtTwelvePercent = false
        }
    }

    func lidTick() {
        do {
            try lidBrightnessCoordinator.tick(isClosedLidModeActive: isClosedLidModeActive)
        } catch {
            lastMessage = "밝기 자동 조정 실패: \(error.localizedDescription)"
        }
    }

    func safetyTick() {
        refresh()

        guard isClosedLidModeActive, let batteryStatus else {
            return
        }

        switch BatterySafetyPolicy.recommendation(for: batteryStatus) {
        case .ok:
            break
        case .disableSoon:
            if !warnedAtTwelvePercent {
                warnedAtTwelvePercent = true
                lastMessage = "배터리 12% 이하입니다. 작업 정리를 준비하세요."
            }
        case .disableNow:
            perform("배터리 10% 이하라 닫힌 상태 작업 모드를 자동으로 종료했습니다.") {
                try service.disableClosedLidMode()
                workModeAssertions.deactivate()
                enabledByThisRun = false
            }
        }
    }

    func restoreBeforeQuit() {
        workModeAssertions.deactivate()

        guard enabledByThisRun else {
            return
        }

        do {
            try service.disableClosedLidMode()
            try lidBrightnessCoordinator.tick(isClosedLidModeActive: false)
        } catch {
            lastMessage = "종료 전 복구 실패: \(error.localizedDescription)"
        }
    }

    private func syncWorkModeAssertions(isActive: Bool) {
        if isActive {
            try? workModeAssertions.activate()
        } else {
            workModeAssertions.deactivate()
        }
    }

    private func perform(_ successMessage: String, action: () throws -> Void) {
        isBusy = true
        defer {
            isBusy = false
            refresh()
        }

        do {
            try action()
            lastMessage = successMessage
        } catch {
            lastMessage = "명령 실패: \(error.localizedDescription)"
        }
    }

    private func statusMessage(for battery: BatteryStatus) -> String {
        let sourceText: String
        switch battery.source {
        case .acPower:
            sourceText = "전원 연결"
        case .battery:
            sourceText = "배터리 사용"
        case .unknown:
            sourceText = "전원 상태 알 수 없음"
        }

        let percentText = battery.percentage.map { "\($0)%" } ?? "잔량 알 수 없음"
        return "\(sourceText), \(percentText)"
    }
}
