import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("PackageManifest Tests")
struct PackageManifestTests {

    @Test("Parse from: version requirement")
    func parseFromRequirement() {
        let content = """
        let package = Package(
            dependencies: [
                .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
            ]
        )
        """

        let parser = PackageManifestParser()
        let manifest = parser.parse(content: content)

        #expect(manifest.dependencies.count == 1)
        #expect(manifest.dependencies[0].url == "https://github.com/apple/swift-argument-parser.git")
        #expect(manifest.dependencies[0].identity == "swift-argument-parser")

        if case .upToNextMajor(let from) = manifest.dependencies[0].requirement {
            #expect(from == SemanticVersion(major: 1, minor: 5, patch: 0))
        } else {
            Issue.record("Expected upToNextMajor requirement")
        }
    }

    @Test("Parse upToNextMajor requirement")
    func parseUpToNextMajor() {
        let content = """
        .package(url: "https://github.com/example/test.git", .upToNextMajor(from: "2.0.0"))
        """

        let parser = PackageManifestParser()
        let manifest = parser.parse(content: content)

        #expect(manifest.dependencies.count == 1)
        if case .upToNextMajor(let from) = manifest.dependencies[0].requirement {
            #expect(from == SemanticVersion(major: 2, minor: 0, patch: 0))
        } else {
            Issue.record("Expected upToNextMajor requirement")
        }
    }

    @Test("Parse upToNextMinor requirement")
    func parseUpToNextMinor() {
        let content = """
        .package(url: "https://github.com/example/test.git", .upToNextMinor(from: "1.2.3"))
        """

        let parser = PackageManifestParser()
        let manifest = parser.parse(content: content)

        #expect(manifest.dependencies.count == 1)
        if case .upToNextMinor(let from) = manifest.dependencies[0].requirement {
            #expect(from == SemanticVersion(major: 1, minor: 2, patch: 3))
        } else {
            Issue.record("Expected upToNextMinor requirement")
        }
    }

    @Test("Parse exact requirement")
    func parseExact() {
        let content = """
        .package(url: "https://github.com/example/test.git", exact: "1.0.0")
        """

        let parser = PackageManifestParser()
        let manifest = parser.parse(content: content)

        #expect(manifest.dependencies.count == 1)
        if case .exact(let version) = manifest.dependencies[0].requirement {
            #expect(version == SemanticVersion(major: 1, minor: 0, patch: 0))
        } else {
            Issue.record("Expected exact requirement")
        }
    }

    @Test("Parse branch requirement")
    func parseBranch() {
        let content = """
        .package(url: "https://github.com/example/test.git", branch: "main")
        """

        let parser = PackageManifestParser()
        let manifest = parser.parse(content: content)

        #expect(manifest.dependencies.count == 1)
        if case .branch(let name) = manifest.dependencies[0].requirement {
            #expect(name == "main")
        } else {
            Issue.record("Expected branch requirement")
        }
    }

    @Test("Parse range requirement")
    func parseRange() {
        let content = """
        .package(url: "https://github.com/example/test.git", "1.0.0"..<"2.0.0")
        """

        let parser = PackageManifestParser()
        let manifest = parser.parse(content: content)

        #expect(manifest.dependencies.count == 1)
        if case .range(let from, let to) = manifest.dependencies[0].requirement {
            #expect(from == SemanticVersion(major: 1, minor: 0, patch: 0))
            #expect(to == SemanticVersion(major: 2, minor: 0, patch: 0))
        } else {
            Issue.record("Expected range requirement")
        }
    }

    @Test("Parse multiple dependencies")
    func parseMultiple() {
        let content = """
        let package = Package(
            dependencies: [
                .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
                .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
            ]
        )
        """

        let parser = PackageManifestParser()
        let manifest = parser.parse(content: content)

        #expect(manifest.dependencies.count == 2)
        #expect(manifest.dependencies[0].identity == "swift-argument-parser")
        #expect(manifest.dependencies[1].identity == "swift-collections")
    }

    @Test("Identity extracted from URL correctly")
    func identityFromURL() {
        let dep1 = ManifestDependency(url: "https://github.com/apple/swift-argument-parser.git", requirement: .unknown)
        let dep2 = ManifestDependency(url: "https://github.com/onevcat/Kingfisher", requirement: .unknown)
        let dep3 = ManifestDependency(url: "git@github.com:apple/swift-nio.git", requirement: .unknown)

        #expect(dep1.identity == "swift-argument-parser")
        #expect(dep2.identity == "kingfisher")
        #expect(dep3.identity == "swift-nio")
    }

    @Test("ManifestDependency with single source path")
    func manifestDependencyWithSingleSourcePath() {
        let dep = ManifestDependency(
            url: "https://github.com/example/test.git",
            requirement: .unknown,
            sourcePath: "/path/to/MyApp.xcodeproj"
        )

        #expect(dep.sourcePaths.count == 1)
        #expect(dep.sourcePaths[0] == "/path/to/MyApp.xcodeproj")
    }

    @Test("ManifestDependency with multiple source paths")
    func manifestDependencyWithMultipleSourcePaths() {
        let dep = ManifestDependency(
            url: "https://github.com/example/test.git",
            requirement: .unknown,
            sourcePaths: ["/path/to/App.xcodeproj", "/path/to/Core/Package.swift"]
        )

        #expect(dep.sourcePaths.count == 2)
        #expect(dep.sourcePaths[0] == "/path/to/App.xcodeproj")
        #expect(dep.sourcePaths[1] == "/path/to/Core/Package.swift")
    }

    @Test("ManifestDependency without source path has empty array")
    func manifestDependencyWithoutSourcePath() {
        let dep = ManifestDependency(
            url: "https://github.com/example/test.git",
            requirement: .unknown
        )

        #expect(dep.sourcePaths.isEmpty)
    }

    @Test("ManifestDependency addingSourcePath creates new instance")
    func manifestDependencyAddingSourcePath() {
        let dep = ManifestDependency(
            url: "https://github.com/example/test.git",
            requirement: .upToNextMajor(from: SemanticVersion(major: 1, minor: 0, patch: 0)),
            sourcePath: "/path/to/App.xcodeproj"
        )

        let updated = dep.addingSourcePath("/path/to/Core/Package.swift")

        #expect(updated.sourcePaths.count == 2)
        #expect(updated.sourcePaths[0] == "/path/to/App.xcodeproj")
        #expect(updated.sourcePaths[1] == "/path/to/Core/Package.swift")
        #expect(updated.url == dep.url)
        #expect(updated.requirement == dep.requirement)
    }
}

@Suite("VersionRequirement Tests")
struct VersionRequirementTests {

    @Test("upToNextMajor satisfies same major versions")
    func upToNextMajorSatisfaction() {
        let requirement = VersionRequirement.upToNextMajor(from: SemanticVersion(major: 1, minor: 0, patch: 0))

        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 0, patch: 0)))
        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 5, patch: 0)))
        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 99, patch: 99)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 2, minor: 0, patch: 0)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 0, minor: 9, patch: 0)))
    }

    @Test("upToNextMinor satisfies same minor versions")
    func upToNextMinorSatisfaction() {
        let requirement = VersionRequirement.upToNextMinor(from: SemanticVersion(major: 1, minor: 2, patch: 0))

        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 2, patch: 0)))
        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 2, patch: 99)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 3, patch: 0)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 2, minor: 2, patch: 0)))
    }

    @Test("exact only satisfies exact version")
    func exactSatisfaction() {
        let requirement = VersionRequirement.exact(SemanticVersion(major: 1, minor: 2, patch: 3))

        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 2, patch: 3)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 2, patch: 4)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 3, patch: 3)))
    }

    @Test("range satisfies versions within range")
    func rangeSatisfaction() {
        let requirement = VersionRequirement.range(
            from: SemanticVersion(major: 1, minor: 0, patch: 0),
            to: SemanticVersion(major: 2, minor: 0, patch: 0)
        )

        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 0, patch: 0)))
        #expect(requirement.isSatisfied(by: SemanticVersion(major: 1, minor: 99, patch: 99)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 2, minor: 0, patch: 0)))
        #expect(!requirement.isSatisfied(by: SemanticVersion(major: 0, minor: 9, patch: 0)))
    }

    @Test("branch always satisfies")
    func branchSatisfaction() {
        let requirement = VersionRequirement.branch("main")
        #expect(requirement.isSatisfied(by: SemanticVersion(major: 99, minor: 99, patch: 99)))
    }
}
