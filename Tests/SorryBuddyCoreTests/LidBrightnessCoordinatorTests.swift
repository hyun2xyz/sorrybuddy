import Testing
@testable import SorryBuddyCore

final class FakeClamshellProvider: ClamshellStateProviding {
    var isClosed = false

    func isClamshellClosed() throws -> Bool {
        isClosed
    }
}

final class FakeBrightnessController: DisplayBrightnessControlling {
    var brightness: Float = 0.6
    var setValues: [Float] = []

    func currentBrightness() throws -> Float {
        brightness
    }

    func setBrightness(_ value: Float) throws {
        brightness = value
        setValues.append(value)
    }
}

struct LidBrightnessCoordinatorTests {
    @Test func setsBrightnessToZeroWhenClosedLidModeIsActiveAndLidCloses() throws {
        let clamshell = FakeClamshellProvider()
        let brightness = FakeBrightnessController()
        let coordinator = LidBrightnessCoordinator(clamshell: clamshell, brightness: brightness)
        clamshell.isClosed = true

        try coordinator.tick(isClosedLidModeActive: true)

        #expect(brightness.setValues == [0])
    }

    @Test func restoresPreviousBrightnessWhenLidReopens() throws {
        let clamshell = FakeClamshellProvider()
        let brightness = FakeBrightnessController()
        let coordinator = LidBrightnessCoordinator(clamshell: clamshell, brightness: brightness)
        clamshell.isClosed = true

        try coordinator.tick(isClosedLidModeActive: true)
        clamshell.isClosed = false
        try coordinator.tick(isClosedLidModeActive: true)

        #expect(brightness.setValues == [0, 0.6])
    }

    @Test func restoresPreviousBrightnessWhenModeTurnsOffWhileLidWasDimmed() throws {
        let clamshell = FakeClamshellProvider()
        let brightness = FakeBrightnessController()
        let coordinator = LidBrightnessCoordinator(clamshell: clamshell, brightness: brightness)
        clamshell.isClosed = true

        try coordinator.tick(isClosedLidModeActive: true)
        try coordinator.tick(isClosedLidModeActive: false)

        #expect(brightness.setValues == [0, 0.6])
    }

    @Test func doesNotDimWhenClosedLidModeIsInactive() throws {
        let clamshell = FakeClamshellProvider()
        let brightness = FakeBrightnessController()
        let coordinator = LidBrightnessCoordinator(clamshell: clamshell, brightness: brightness)
        clamshell.isClosed = true

        try coordinator.tick(isClosedLidModeActive: false)

        #expect(brightness.setValues.isEmpty)
    }
}
