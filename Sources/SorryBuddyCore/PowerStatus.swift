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
}
