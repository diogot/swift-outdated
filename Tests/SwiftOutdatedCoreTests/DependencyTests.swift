import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("Dependency Tests")
struct DependencyTests {

    @Test("Create dependency from pin")
    func createFromPin() {
        let pin = PackageResolved.Pin(
            identity: "test-package",
            kind: "remoteSourceControl",
            location: "https://github.com/example/test.git",
            state: PackageResolved.Pin.State(
                revision: "abc123",
                version: "1.2.3",
                branch: nil
            )
        )

        let dependency = Dependency.from(pin: pin)

        #expect(dependency.name == "test-package")
        #expect(dependency.repositoryURL == "https://github.com/example/test.git")
        #expect(dependency.currentVersion == SemanticVersion(major: 1, minor: 2, patch: 3))
        #expect(dependency.currentRevision == "abc123")
        #expect(dependency.branch == nil)
    }

    @Test("Dependency is outdated when latest > current")
    func isOutdatedWhenLatestGreater() {
        let dependency = Dependency(
            name: "test",
            repositoryURL: "https://example.com/test.git",
            currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
            currentRevision: "abc",
            latestVersion: SemanticVersion(major: 2, minor: 0, patch: 0)
        )

        #expect(dependency.isOutdated == true)
    }

    @Test("Dependency is not outdated when current >= latest")
    func isNotOutdatedWhenCurrentGreaterOrEqual() {
        let dependency1 = Dependency(
            name: "test",
            repositoryURL: "https://example.com/test.git",
            currentVersion: SemanticVersion(major: 2, minor: 0, patch: 0),
            currentRevision: "abc",
            latestVersion: SemanticVersion(major: 1, minor: 0, patch: 0)
        )

        let dependency2 = Dependency(
            name: "test",
            repositoryURL: "https://example.com/test.git",
            currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
            currentRevision: "abc",
            latestVersion: SemanticVersion(major: 1, minor: 0, patch: 0)
        )

        #expect(dependency1.isOutdated == false)
        #expect(dependency2.isOutdated == false)
    }

    @Test("Dependency without latest version is not outdated")
    func notOutdatedWithoutLatest() {
        let dependency = Dependency(
            name: "test",
            repositoryURL: "https://example.com/test.git",
            currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
            currentRevision: "abc",
            latestVersion: nil
        )

        #expect(dependency.isOutdated == false)
    }

    @Test("withLatestVersion creates new dependency with updated version")
    func withLatestVersionCreatesNew() {
        let original = Dependency(
            name: "test",
            repositoryURL: "https://example.com/test.git",
            currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
            currentRevision: "abc"
        )

        let updated = original.withLatestVersion(SemanticVersion(major: 2, minor: 0, patch: 0))

        #expect(updated.latestVersion == SemanticVersion(major: 2, minor: 0, patch: 0))
        #expect(updated.name == original.name)
        #expect(updated.currentVersion == original.currentVersion)
    }
}

@Suite("SemanticVersion Tests")
struct SemanticVersionTests {

    @Test("Parse standard version")
    func parseStandardVersion() {
        let version = SemanticVersion.parse("1.2.3")
        #expect(version == SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    @Test("Parse version with v prefix")
    func parseWithVPrefix() {
        let version = SemanticVersion.parse("v1.2.3")
        #expect(version == SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    @Test("Parse version with prerelease")
    func parseWithPrerelease() {
        let version = SemanticVersion.parse("1.2.3-beta.1")
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
        #expect(version?.prerelease == "beta.1")
    }

    @Test("Parse version with build metadata")
    func parseWithBuildMetadata() {
        let version = SemanticVersion.parse("1.2.3+build.456")
        #expect(version?.major == 1)
        #expect(version?.buildMetadata == "build.456")
    }

    @Test("Parse partial version")
    func parsePartialVersion() {
        let v1 = SemanticVersion.parse("1")
        let v2 = SemanticVersion.parse("1.2")

        #expect(v1 == SemanticVersion(major: 1, minor: 0, patch: 0))
        #expect(v2 == SemanticVersion(major: 1, minor: 2, patch: 0))
    }

    @Test("Version comparison")
    func versionComparison() {
        let v1_0_0 = SemanticVersion(major: 1, minor: 0, patch: 0)
        let v1_0_1 = SemanticVersion(major: 1, minor: 0, patch: 1)
        let v1_1_0 = SemanticVersion(major: 1, minor: 1, patch: 0)
        let v2_0_0 = SemanticVersion(major: 2, minor: 0, patch: 0)

        #expect(v1_0_0 < v1_0_1)
        #expect(v1_0_1 < v1_1_0)
        #expect(v1_1_0 < v2_0_0)
        #expect(!(v2_0_0 < v1_0_0))
    }

    @Test("Prerelease has lower precedence than release")
    func prereleaseVsRelease() {
        let prerelease = SemanticVersion(major: 1, minor: 0, patch: 0, prerelease: "alpha")
        let release = SemanticVersion(major: 1, minor: 0, patch: 0)

        #expect(prerelease < release)
    }

    @Test("Version description")
    func versionDescription() {
        let v1 = SemanticVersion(major: 1, minor: 2, patch: 3)
        let v2 = SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "beta")
        let v3 = SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "beta", buildMetadata: "build.1")

        #expect(v1.description == "1.2.3")
        #expect(v2.description == "1.2.3-beta")
        #expect(v3.description == "1.2.3-beta+build.1")
    }

    @Test("Invalid version returns nil")
    func invalidVersionReturnsNil() {
        #expect(SemanticVersion.parse("not-a-version") == nil)
        #expect(SemanticVersion.parse("") == nil)
    }
}
