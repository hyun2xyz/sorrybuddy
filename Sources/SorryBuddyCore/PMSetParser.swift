import Foundation

public enum PMSetParser {
    public static func parsePowerSettings(_ output: String) throws -> PowerSettings {
        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.first == "SleepDisabled", let value = fields.dropFirst().first else {
                continue
            }

            return PowerSettings(closedLidSleepDisabled: value == "1")
        }

        throw SorryBuddyError.missingPowerSetting("SleepDisabled")
    }

    public static func parseBatteryStatus(_ output: String) throws -> BatteryStatus {
        let source = parsePowerSource(output)
        let percentage = try parseBatteryPercentage(output)
        let isCharging = output
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .contains { field in
                field == "charging" || field == "charged" || field == "finishing charge"
            }

        return BatteryStatus(source: source, percentage: percentage, isCharging: isCharging)
    }

    private static func parsePowerSource(_ output: String) -> PowerSource {
        if output.contains("Now drawing from 'AC Power'") {
            return .acPower
        }

        if output.contains("Now drawing from 'Battery Power'") {
            return .battery
        }

        return .unknown
    }

    private static func parseBatteryPercentage(_ output: String) throws -> Int {
        let pattern = #"(\d{1,3})%;"#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(output.startIndex..<output.endIndex, in: output)

        guard
            let match = regex.firstMatch(in: output, range: range),
            let percentRange = Range(match.range(at: 1), in: output),
            let percentage = Int(output[percentRange])
        else {
            throw SorryBuddyError.missingBatteryPercentage
        }

        return percentage
    }
}
