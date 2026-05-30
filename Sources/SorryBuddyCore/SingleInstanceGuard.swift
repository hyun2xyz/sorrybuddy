import Foundation

public struct RunningAppSnapshot: Equatable {
    public let bundleIdentifier: String?
    public let processIdentifier: Int32
    public let isTerminated: Bool

    public init(bundleIdentifier: String?, processIdentifier: Int32, isTerminated: Bool) {
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.isTerminated = isTerminated
    }
}

public enum SingleInstanceGuard {
    public static func existingProcessIdentifier(
        bundleIdentifier: String?,
        currentProcessIdentifier: Int32,
        runningApplications: [RunningAppSnapshot]
    ) -> Int32? {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            return nil
        }

        return runningApplications.first { app in
            app.bundleIdentifier == bundleIdentifier &&
                app.processIdentifier != currentProcessIdentifier &&
                !app.isTerminated
        }?.processIdentifier
    }
}
