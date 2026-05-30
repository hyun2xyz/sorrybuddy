import Foundation
import Testing
@testable import SorryBuddyCore

struct UpdateCheckerTests {
    @Test func reportsUpdateWhenLatestReleaseIsNewer() throws {
        let release = GitHubRelease(
            tagName: "v0.2.0",
            htmlURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/tag/v0.2.0")!,
            assets: [
                GitHubReleaseAsset(
                    name: "SorryBuddy-0.2.0.dmg",
                    browserDownloadURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/download/v0.2.0/SorryBuddy-0.2.0.dmg")!
                )
            ]
        )

        let outcome = try UpdateInterpreter.outcome(for: release, currentVersion: "0.1.0")

        #expect(outcome == .updateAvailable(UpdateInfo(
            latestVersion: "0.2.0",
            releaseURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/tag/v0.2.0")!,
            downloadURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/download/v0.2.0/SorryBuddy-0.2.0.dmg")!
        )))
    }

    @Test func reportsUpToDateWhenLatestReleaseMatchesCurrentVersion() throws {
        let release = GitHubRelease(
            tagName: "v0.1.0",
            htmlURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/tag/v0.1.0")!,
            assets: []
        )

        let outcome = try UpdateInterpreter.outcome(for: release, currentVersion: "0.1.0")

        #expect(outcome == .upToDate(version: "0.1.0"))
    }

    @Test func fallsBackToReleasePageWhenNoDMGAssetExists() throws {
        let release = GitHubRelease(
            tagName: "v0.2.0",
            htmlURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/tag/v0.2.0")!,
            assets: [
                GitHubReleaseAsset(
                    name: "source.zip",
                    browserDownloadURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/archive/refs/tags/v0.2.0.zip")!
                )
            ]
        )

        let outcome = try UpdateInterpreter.outcome(for: release, currentVersion: "0.1.0")

        #expect(outcome == .updateAvailable(UpdateInfo(
            latestVersion: "0.2.0",
            releaseURL: URL(string: "https://github.com/hyun2xyz/sorrybuddy/releases/tag/v0.2.0")!,
            downloadURL: nil
        )))
    }
}
