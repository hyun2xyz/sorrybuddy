import Foundation

public enum PowerSource: Equatable {
    case acPower
    case battery
    case unknown
}

public struct PowerSettings: Equatable {
    public let closedLidSleepDisabled: Bool

    public init(closedLidSleepDisabled: Bool) {
        self.closedLidSleepDisabled = closedLidSleepDisabled
    }
}

public struct BatteryStatus: Equatable {
    public let source: PowerSource
    public let percentage: Int?
    public let isCharging: Bool

    public init(source: PowerSource, percentage: Int?, isCharging: Bool) {
        self.source = source
        self.percentage = percentage
        self.isCharging = isCharging
    }
}

public enum SorryBuddyError: Error, Equatable {
    case missingPowerSetting(String)
    case missingBatteryPercentage
    case closedLidModeNotApplied
    case powerAssertionFailed(String, Int32)
}

extension SorryBuddyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingPowerSetting(let setting):
            return "전원 설정에서 \(setting) 값을 찾지 못했습니다."
        case .missingBatteryPercentage:
            return "배터리 잔량을 읽지 못했습니다."
        case .closedLidModeNotApplied:
            return "macOS 전원 설정에 닫힌 상태 작업 모드가 적용되지 않았습니다."
        case .powerAssertionFailed(let assertionType, let code):
            return "\(assertionType) 전원 보강 설정에 실패했습니다. 코드: \(code)"
        }
    }
}
