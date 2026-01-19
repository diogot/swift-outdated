import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("VersionChecker Tests")
struct VersionCheckerTests {

    @Test("Find latest version from tags")
    func findLatestVersion() {
        let checker = VersionChecker()
        let tags = ["0.9.0", "1.0.0", "1.1.0", "1.2.0", "v2.0.0"]

        let latest = checker.findLatestVersion(from: tags)

        #expect(latest == SemanticVersion(major: 2, minor: 0, patch: 0))
    }

    @Test("Excludes prerelease versions from latest")
    func excludesPrereleases() {
        let checker = VersionChecker()
        let tags = ["1.0.0", "1.1.0", "2.0.0-alpha", "2.0.0-beta.1"]

        let latest = checker.findLatestVersion(from: tags)

        #expect(latest == SemanticVersion(major: 1, minor: 1, patch: 0))
    }

    @Test("Returns nil for empty tags")
    func emptyTagsReturnsNil() {
        let checker = VersionChecker()
        let latest = checker.findLatestVersion(from: [])
        #expect(latest == nil)
    }

    @Test("Returns nil for non-semver tags")
    func nonSemverTagsReturnsNil() {
        let checker = VersionChecker()
        let tags = ["release-candidate", "stable", "latest"]
        let latest = checker.findLatestVersion(from: tags)
        #expect(latest == nil)
    }

    @Test("Check for updates populates latest version")
    func checkForUpdatesPopulatesLatest() async {
        let mockFetcher = MockGitTagFetcher()
        mockFetcher.setTags(["1.0.0", "2.0.0"], for: "https://github.com/example/package-a.git")
        mockFetcher.setTags(["0.5.0", "1.0.0"], for: "https://github.com/example/package-b.git")

        let checker = VersionChecker(tagFetcher: mockFetcher)

        let dependencies = [
            Dependency(
                name: "package-a",
                repositoryURL: "https://github.com/example/package-a.git",
                currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
                currentRevision: "abc"
            ),
            Dependency(
                name: "package-b",
                repositoryURL: "https://github.com/example/package-b.git",
                currentVersion: SemanticVersion(major: 0, minor: 5, patch: 0),
                currentRevision: "def"
            )
        ]

        let results = await checker.checkForUpdates(dependencies)

        let packageA = results.first { $0.name == "package-a" }
        let packageB = results.first { $0.name == "package-b" }

        #expect(packageA?.latestVersion == SemanticVersion(major: 2, minor: 0, patch: 0))
        #expect(packageB?.latestVersion == SemanticVersion(major: 1, minor: 0, patch: 0))
    }

    @Test("Branch-pinned dependencies don't get latest version")
    func branchPinnedNoLatest() async {
        let mockFetcher = MockGitTagFetcher()
        mockFetcher.setTags(["1.0.0", "2.0.0"], for: "https://github.com/example/repo.git")

        let checker = VersionChecker(tagFetcher: mockFetcher)

        let dependency = Dependency(
            name: "dev-package",
            repositoryURL: "https://github.com/example/repo.git",
            currentVersion: nil,
            currentRevision: "abc123",
            branch: "main"
        )

        let results = await checker.checkForUpdates([dependency])

        #expect(results[0].latestVersion == nil)
    }

    @Test("Results are sorted by name")
    func resultsSortedByName() async {
        let mockFetcher = MockGitTagFetcher()
        let checker = VersionChecker(tagFetcher: mockFetcher)

        let dependencies = [
            Dependency(name: "zebra", repositoryURL: "url", currentVersion: nil, currentRevision: "a"),
            Dependency(name: "Alpha", repositoryURL: "url", currentVersion: nil, currentRevision: "b"),
            Dependency(name: "beta", repositoryURL: "url", currentVersion: nil, currentRevision: "c")
        ]

        let results = await checker.checkForUpdates(dependencies)

        #expect(results.map(\.name) == ["Alpha", "beta", "zebra"])
    }
}
