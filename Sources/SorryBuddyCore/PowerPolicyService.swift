import Foundation

public final class PowerPolicyService {
    private let shell: ShellRunning

    public init(shell: ShellRunning = SystemShellClient()) {
        self.shell = shell
    }

    public func enableClosedLidMode() throws {
        try runAdministratorPMSet(command: "/usr/bin/pmset -a disablesleep 1")
        guard try currentPowerSettings().closedLidSleepDisabled else {
            throw SorryBuddyError.closedLidModeNotApplied
        }
    }

    public func disableClosedLidMode() throws {
        try runAdministratorPMSet(command: "/usr/bin/pmset -a disablesleep 0")
    }

    public func currentPowerSettings() throws -> PowerSettings {
        let output = try shell.run(ShellCommand(executable: "/usr/bin/pmset", arguments: ["-g"]))

        do {
            return try PMSetParser.parsePowerSettings(output)
        } catch SorryBuddyError.missingPowerSetting("SleepDisabled") {
            return PowerSettings(closedLidSleepDisabled: false)
        }
    }

    public func currentBatteryStatus() throws -> BatteryStatus {
        let output = try shell.run(ShellCommand(executable: "/usr/bin/pmset", arguments: ["-g", "batt"]))
        return try PMSetParser.parseBatteryStatus(output)
    }

    private func runAdministratorPMSet(command: String) throws {
        try shell.run(ShellCommand(
            executable: "/usr/bin/osascript",
            arguments: [
                "-e",
                "do shell script \"\(command)\" with administrator privileges"
            ]
        ))
    }
}

public enum BatterySafetyRecommendation: Equatable {
    case ok
    case disableSoon
    case disableNow
}

public enum BatterySafetyPolicy {
    public static func recommendation(for status: BatteryStatus) -> BatterySafetyRecommendation {
        guard status.source == .battery, let percentage = status.percentage else {
            return .ok
        }

        if percentage <= 10 {
            return .disableNow
        }

        if percentage <= 12 {
            return .disableSoon
        }

        return .ok
    }
}
