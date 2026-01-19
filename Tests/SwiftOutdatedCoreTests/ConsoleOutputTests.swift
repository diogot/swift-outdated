import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("ConsoleOutput Tests")
struct ConsoleOutputTests {
    let output = ConsoleOutput()

    @Test("Format table with outdated dependencies")
    func formatTableWithOutdated() {
        let dependencies = [
            Dependency(
                name: "swift-argument-parser",
                repositoryURL: "https://github.com/apple/swift-argument-parser.git",
                currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
                currentRevision: "abc",
                latestVersion: SemanticVersion(major: 1, minor: 5, patch: 0)
            ),
            Dependency(
                name: "swift-collections",
                repositoryURL: "https://github.com/apple/swift-collections.git",
                currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
                currentRevision: "def",
                latestVersion: SemanticVersion(major: 1, minor: 1, patch: 0)
            )
        ]

        let result = output.formatTable(dependencies)

        #expect(result.contains("swift-argument-parser"))
        #expect(result.contains("swift-collections"))
        #expect(result.contains("1.0.0"))
        #expect(result.contains("1.5.0"))
        #expect(result.contains("1.1.0"))
        #expect(result.contains("Package"))
        #expect(result.contains("Current"))
        #expect(result.contains("Latest"))
    }

    @Test("Format table shows up to date message when no outdated")
    func formatTableUpToDate() {
        let dependencies = [
            Dependency(
                name: "package",
                repositoryURL: "url",
                currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
                currentRevision: "abc",
                latestVersion: SemanticVersion(major: 1, minor: 0, patch: 0)
            )
        ]

        let result = output.formatTable(dependencies)

        #expect(result == "All dependencies are up to date!")
    }

    @Test("Format table with empty list shows up to date")
    func formatTableEmpty() {
        let result = output.formatTable([])
        #expect(result == "All dependencies are up to date!")
    }

    @Test("Format JSON with outdated dependencies")
    func formatJSONWithOutdated() throws {
        let dependencies = [
            Dependency(
                name: "swift-argument-parser",
                repositoryURL: "https://github.com/apple/swift-argument-parser.git",
                currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
                currentRevision: "abc",
                latestVersion: SemanticVersion(major: 1, minor: 5, patch: 0)
            )
        ]

        let result = try output.formatJSON(dependencies)

        #expect(result.contains("swift-argument-parser"))
        #expect(result.contains("1.0.0"))
        #expect(result.contains("1.5.0"))
        #expect(result.contains("repositoryURL"))
    }

    @Test("Format JSON with empty outdated list")
    func formatJSONEmpty() throws {
        let dependencies = [
            Dependency(
                name: "package",
                repositoryURL: "url",
                currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
                currentRevision: "abc",
                latestVersion: SemanticVersion(major: 1, minor: 0, patch: 0)
            )
        ]

        let result = try output.formatJSON(dependencies)
        #expect(result == "[\n\n]")
    }

    @Test("Format JSON is valid JSON")
    func formatJSONIsValid() throws {
        let dependencies = [
            Dependency(
                name: "test",
                repositoryURL: "https://example.com/test.git",
                currentVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
                currentRevision: "abc",
                latestVersion: SemanticVersion(major: 2, minor: 0, patch: 0)
            )
        ]

        let jsonString = try output.formatJSON(dependencies)
        let data = jsonString.data(using: .utf8)!

        // Should not throw - valid JSON
        let parsed = try JSONSerialization.jsonObject(with: data)
        #expect(parsed is [[String: Any]])
    }
}
