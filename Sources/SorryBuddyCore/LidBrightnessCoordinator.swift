import CoreGraphics
import Foundation
import IOKit

public protocol ClamshellStateProviding: AnyObject {
    func isClamshellClosed() throws -> Bool
}

public protocol DisplayBrightnessControlling: AnyObject {
    func currentBrightness() throws -> Float
    func setBrightness(_ value: Float) throws
}

public final class LidBrightnessCoordinator {
    private let clamshell: ClamshellStateProviding
    private let brightness: DisplayBrightnessControlling
    private var savedBrightness: Float?

    public init(
        clamshell: ClamshellStateProviding = SystemClamshellStateProvider(),
        brightness: DisplayBrightnessControlling = DisplayServicesBrightnessController()
    ) {
        self.clamshell = clamshell
        self.brightness = brightness
    }

    public func tick(isClosedLidModeActive: Bool) throws {
        guard isClosedLidModeActive else {
            try restoreIfNeeded()
            return
        }

        if try clamshell.isClamshellClosed() {
            try dimIfNeeded()
        } else {
            try restoreIfNeeded()
        }
    }

    private func dimIfNeeded() throws {
        guard savedBrightness == nil else {
            return
        }

        savedBrightness = try brightness.currentBrightness()
        try brightness.setBrightness(0)
    }

    private func restoreIfNeeded() throws {
        guard let savedBrightness else {
            return
        }

        try brightness.setBrightness(savedBrightness)
        self.savedBrightness = nil
    }
}

public final class SystemClamshellStateProvider: ClamshellStateProviding {
    public init() {}

    public func isClamshellClosed() throws -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else {
            throw SorryBuddyError.missingPowerSetting("IOPMrootDomain")
        }
        defer {
            IOObjectRelease(service)
        }

        guard
            let value = IORegistryEntryCreateCFProperty(
                service,
                "AppleClamshellState" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue()
        else {
            throw SorryBuddyError.missingPowerSetting("AppleClamshellState")
        }

        return CFBooleanGetValue((value as! CFBoolean))
    }
}

public final class DisplayServicesBrightnessController: DisplayBrightnessControlling {
    public init() {}

    public func currentBrightness() throws -> Float {
        var value: Float = 0
        let result = DisplayServicesGetBrightness(CGMainDisplayID(), &value)

        guard result == 0 else {
            throw BrightnessError.readFailed(result)
        }

        return value
    }

    public func setBrightness(_ value: Float) throws {
        let clamped = min(max(value, 0), 1)
        let result = DisplayServicesSetBrightness(CGMainDisplayID(), clamped)

        guard result == 0 else {
            throw BrightnessError.writeFailed(result)
        }
    }
}

public enum BrightnessError: Error, Equatable {
    case readFailed(Int32)
    case writeFailed(Int32)
}

@_silgen_name("DisplayServicesGetBrightness")
private func DisplayServicesGetBrightness(
    _ display: CGDirectDisplayID,
    _ brightness: UnsafeMutablePointer<Float>
) -> Int32

@_silgen_name("DisplayServicesSetBrightness")
private func DisplayServicesSetBrightness(
    _ display: CGDirectDisplayID,
    _ brightness: Float
) -> Int32
