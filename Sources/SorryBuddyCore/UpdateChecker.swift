import Foundation

public struct GitHubRelease: Decodable, Equatable, Sendable {
    public let tagName: String
    public let htmlURL: URL
    public let assets: [GitHubReleaseAsset]

    public init(tagName: String, htmlURL: URL, assets: [GitHubReleaseAsset]) {
        self.tagName = tagName
        self.htmlURL = htmlURL
        self.assets = assets
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }
}

public struct GitHubReleaseAsset: Decodable, Equatable, Sendable {
    public let name: String
    public let browserDownloadURL: URL

    public init(name: String, browserDownloadURL: URL) {
        self.name = name
        self.browserDownloadURL = browserDownloadURL
    }

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

public struct UpdateInfo: Equatable, Sendable {
    public let latestVersion: String
    public let releaseURL: URL
    public let downloadURL: URL?

    public init(latestVersion: String, releaseURL: URL, downloadURL: URL?) {
        self.latestVersion = latestVersion
        self.releaseURL = releaseURL
        self.downloadURL = downloadURL
    }
}

public enum UpdateCheckOutcome: Equatable, Sendable {
    case upToDate(version: String)
    case updateAvailable(UpdateInfo)
}

public enum UpdateInterpreter {
    public static func outcome(for release: GitHubRelease, currentVersion: String) throws -> UpdateCheckOutcome {
        let latestVersion = normalizeVersion(release.tagName)
        let currentVersion = normalizeVersion(currentVersion)

        guard isNewer(latestVersion, than: currentVersion) else {
            return .upToDate(version: currentVersion)
        }

        return .updateAvailable(UpdateInfo(
            latestVersion: latestVersion,
            releaseURL: release.htmlURL,
            downloadURL: release.assets.first { $0.name.localizedCaseInsensitiveContains(".dmg") }?.browserDownloadURL
        ))
    }

    private static func normalizeVersion(_ version: String) -> String {
        String(version.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingPrefix("v")
            .trimmingPrefix("V"))
    }

    private static func isNewer(_ latest: String, than current: String) -> Bool {
        let latestParts = versionParts(latest)
        let currentParts = versionParts(current)
        let count = max(latestParts.count, currentParts.count)

        for index in 0..<count {
            let latestPart = index < latestParts.count ? latestParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0

            if latestPart != currentPart {
                return latestPart > currentPart
            }
        }

        return false
    }

    private static func versionParts(_ version: String) -> [Int] {
        version
            .split(separator: ".")
            .map { part in
                let numericPrefix = part.prefix { $0.isNumber }
                return Int(numericPrefix) ?? 0
            }
    }
}

public final class GitHubUpdateChecker: @unchecked Sendable {
    private let currentVersion: String
    private let latestReleaseURL: URL
    private let session: URLSession

    public init(
        currentVersion: String,
        latestReleaseURL: URL = URL(string: "https://api.github.com/repos/hyun2xyz/sorrybuddy/releases/latest")!,
        session: URLSession = .shared
    ) {
        self.currentVersion = currentVersion
        self.latestReleaseURL = latestReleaseURL
        self.session = session
    }

    public func checkForUpdate() async throws -> UpdateCheckOutcome {
        var request = URLRequest(url: latestReleaseURL)
        request.setValue("SorryBuddy/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw UpdateCheckError.invalidResponse
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        return try UpdateInterpreter.outcome(for: release, currentVersion: currentVersion)
    }
}

public enum UpdateCheckError: Error, Equatable, Sendable {
    case invalidResponse
}
