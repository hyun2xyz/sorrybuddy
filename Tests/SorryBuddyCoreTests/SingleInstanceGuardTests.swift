import Testing
@testable import SorryBuddyCore

struct SingleInstanceGuardTests {
    @Test func findsExistingProcessWithSameBundleIdentifier() {
        let runningApps = [
            RunningAppSnapshot(bundleIdentifier: "xyz.hyun2.sorrybuddy", processIdentifier: 11, isTerminated: false),
            RunningAppSnapshot(bundleIdentifier: "xyz.hyun2.sorrybuddy", processIdentifier: 22, isTerminated: false)
        ]

        let existing = SingleInstanceGuard.existingProcessIdentifier(
            bundleIdentifier: "xyz.hyun2.sorrybuddy",
            currentProcessIdentifier: 22,
            runningApplications: runningApps
        )

        #expect(existing == 11)
    }

    @Test func ignoresCurrentAndTerminatedProcesses() {
        let runningApps = [
            RunningAppSnapshot(bundleIdentifier: "xyz.hyun2.sorrybuddy", processIdentifier: 22, isTerminated: false),
            RunningAppSnapshot(bundleIdentifier: "xyz.hyun2.sorrybuddy", processIdentifier: 33, isTerminated: true)
        ]

        let existing = SingleInstanceGuard.existingProcessIdentifier(
            bundleIdentifier: "xyz.hyun2.sorrybuddy",
            currentProcessIdentifier: 22,
            runningApplications: runningApps
        )

        #expect(existing == nil)
    }

    @Test func ignoresOtherBundleIdentifiersAndMissingBundleIdentifier() {
        let runningApps = [
            RunningAppSnapshot(bundleIdentifier: "com.apple.finder", processIdentifier: 11, isTerminated: false),
            RunningAppSnapshot(bundleIdentifier: nil, processIdentifier: 12, isTerminated: false)
        ]

        let existing = SingleInstanceGuard.existingProcessIdentifier(
            bundleIdentifier: "xyz.hyun2.sorrybuddy",
            currentProcessIdentifier: 22,
            runningApplications: runningApps
        )

        #expect(existing == nil)
    }
}
