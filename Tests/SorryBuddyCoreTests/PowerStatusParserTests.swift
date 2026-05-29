import Testing
@testable import SorryBuddyCore

struct PowerStatusParserTests {
    @Test func parsesDisabledSleepWhenPmsetReportsSleepDisabled() throws {
        let output = """
        Currently in use:
         standby              1
         SleepDisabled        1
         displaysleep         20
         sleep                0
        """

        let status = try PMSetParser.parsePowerSettings(output)

        #expect(status.closedLidSleepDisabled)
    }

    @Test func parsesEnabledSleepWhenSleepDisabledIsZero() throws {
        let output = """
        Currently in use:
         standby              1
         SleepDisabled        0
         displaysleep         20
         sleep                1
        """

        let status = try PMSetParser.parsePowerSettings(output)

        #expect(!status.closedLidSleepDisabled)
    }

    @Test func parsesBatteryPercentageAndPowerSource() throws {
        let output = """
        Now drawing from 'Battery Power'
         -InternalBattery-0 (id=31457379)\t24%; discharging; 2:01 remaining present: true
        """

        let status = try PMSetParser.parseBatteryStatus(output)

        #expect(status.source == .battery)
        #expect(status.percentage == 24)
        #expect(!status.isCharging)
    }

    @Test func parsesAcPowerAndChargingState() throws {
        let output = """
        Now drawing from 'AC Power'
         -InternalBattery-0 (id=31457379)\t99%; finishing charge; 0:00 remaining present: true
        """

        let status = try PMSetParser.parseBatteryStatus(output)

        #expect(status.source == .acPower)
        #expect(status.percentage == 99)
        #expect(status.isCharging)
    }
}
