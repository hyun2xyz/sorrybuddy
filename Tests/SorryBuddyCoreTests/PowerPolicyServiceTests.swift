import Testing
@testable import SorryBuddyCore

final class SpyShellClient: ShellRunning {
    var commands: [ShellCommand] = []
    var outputs: [String] = []

    func run(_ command: ShellCommand) throws -> String {
        commands.append(command)
        return outputs.isEmpty ? "" : outputs.removeFirst()
    }
}

struct PowerPolicyServiceTests {
    @Test func enableClosedLidModeRunsAdministratorPmsetCommand() throws {
        let shell = SpyShellClient()
        let service = PowerPolicyService(shell: shell)

        try service.enableClosedLidMode()

        #expect(shell.commands == [
            ShellCommand(
                executable: "/usr/bin/osascript",
                arguments: [
                    "-e",
                    "do shell script \"/usr/bin/pmset -a disablesleep 1\" with administrator privileges"
                ]
            )
        ])
    }

    @Test func disableClosedLidModeRunsAdministratorPmsetCommand() throws {
        let shell = SpyShellClient()
        let service = PowerPolicyService(shell: shell)

        try service.disableClosedLidMode()

        #expect(shell.commands == [
            ShellCommand(
                executable: "/usr/bin/osascript",
                arguments: [
                    "-e",
                    "do shell script \"/usr/bin/pmset -a disablesleep 0\" with administrator privileges"
                ]
            )
        ])
    }

    @Test func readsCurrentPowerSettingsFromPmset() throws {
        let shell = SpyShellClient()
        shell.outputs = [
            """
            Currently in use:
             SleepDisabled        1
            """
        ]
        let service = PowerPolicyService(shell: shell)

        let settings = try service.currentPowerSettings()

        #expect(settings.closedLidSleepDisabled)
        #expect(shell.commands == [
            ShellCommand(executable: "/usr/bin/pmset", arguments: ["-g"])
        ])
    }

    @Test func batterySafetyRequestsDisableNowAtTwentyPercentOnBattery() {
        let status = BatteryStatus(source: .battery, percentage: 20, isCharging: false)

        #expect(BatterySafetyPolicy.recommendation(for: status) == .disableNow)
    }

    @Test func batterySafetyWarnsAtTwentyTwoPercentOnBattery() {
        let status = BatteryStatus(source: .battery, percentage: 22, isCharging: false)

        #expect(BatterySafetyPolicy.recommendation(for: status) == .disableSoon)
    }

    @Test func batterySafetyAllowsAcPowerAtLowBattery() {
        let status = BatteryStatus(source: .acPower, percentage: 12, isCharging: true)

        #expect(BatterySafetyPolicy.recommendation(for: status) == .ok)
    }
}
