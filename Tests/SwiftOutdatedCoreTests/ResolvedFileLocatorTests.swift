import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("ResolvedFileLocator Tests")
struct ResolvedFileLocatorTests {
    let locator = ResolvedFileLocator()

    @Test("Locate direct Package.resolved path")
    func locateDirectPath() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = tempDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = try locator.locate(from: resolvedPath.path)
        #expect(result == resolvedPath.path)
    }

    @Test("Locate Package.resolved in directory")
    func locateInDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = tempDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = try locator.locate(from: tempDir.path)
        #expect(result == resolvedPath.path)
    }

    @Test("Locate Package.resolved in xcodeproj")
    func locateInXcodeproj() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let xcodeprojDir = tempDir.appendingPathComponent("MyApp.xcodeproj")
        let spmDir = xcodeprojDir
            .appendingPathComponent("project.xcworkspace")
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: spmDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = spmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = try locator.locate(from: xcodeprojDir.path)
        #expect(result == resolvedPath.path)
    }

    @Test("Locate Package.resolved in xcworkspace")
    func locateInXcworkspace() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let xcworkspaceDir = tempDir.appendingPathComponent("MyApp.xcworkspace")
        let spmDir = xcworkspaceDir
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: spmDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = spmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = try locator.locate(from: xcworkspaceDir.path)
        #expect(result == resolvedPath.path)
    }

    @Test("Find xcodeproj in directory")
    func findXcodeprojInDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let xcodeprojDir = tempDir.appendingPathComponent("MyApp.xcodeproj")
        let spmDir = xcodeprojDir
            .appendingPathComponent("project.xcworkspace")
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: spmDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = spmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = try locator.locate(from: tempDir.path)
        #expect(result == resolvedPath.path)
    }

    @Test("Throws when Package.resolved not found")
    func throwsWhenNotFound() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        #expect(throws: PackageResolvedError.self) {
            try locator.locate(from: tempDir.path)
        }
    }

    @Test("Prefers xcworkspace over xcodeproj in same directory")
    func prefersXcworkspaceOverXcodeproj() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Create xcodeproj with Package.resolved
        let xcodeprojDir = tempDir.appendingPathComponent("MyApp.xcodeproj")
        let xcodeprojSpmDir = xcodeprojDir
            .appendingPathComponent("project.xcworkspace")
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: xcodeprojSpmDir, withIntermediateDirectories: true)
        let xcodeprojResolved = xcodeprojSpmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: xcodeprojResolved, atomically: true, encoding: .utf8)

        // Create xcworkspace with Package.resolved
        let xcworkspaceDir = tempDir.appendingPathComponent("MyApp.xcworkspace")
        let xcworkspaceSpmDir = xcworkspaceDir
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: xcworkspaceSpmDir, withIntermediateDirectories: true)
        let xcworkspaceResolved = xcworkspaceSpmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: xcworkspaceResolved, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        let result = try locator.locate(from: tempDir.path)
        #expect(result == xcworkspaceResolved.path)
    }

    @Test("Finds xcworkspace Package.resolved in parent directory")
    func findsXcworkspaceInParentDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Create xcworkspace with Package.resolved in root
        let xcworkspaceDir = tempDir.appendingPathComponent("MyApp.xcworkspace")
        let xcworkspaceSpmDir = xcworkspaceDir
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: xcworkspaceSpmDir, withIntermediateDirectories: true)
        let xcworkspaceResolved = xcworkspaceSpmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: xcworkspaceResolved, atomically: true, encoding: .utf8)

        // Create subdirectory (simulating Services/)
        let subDir = tempDir.appendingPathComponent("Services")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        let result = try locator.locate(from: subDir.path)
        #expect(result == xcworkspaceResolved.path)
    }

    @Test("Prefers parent xcworkspace over local xcodeproj")
    func prefersParentXcworkspaceOverLocalXcodeproj() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Create xcworkspace with Package.resolved in root
        let xcworkspaceDir = tempDir.appendingPathComponent("MyApp.xcworkspace")
        let xcworkspaceSpmDir = xcworkspaceDir
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: xcworkspaceSpmDir, withIntermediateDirectories: true)
        let xcworkspaceResolved = xcworkspaceSpmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: xcworkspaceResolved, atomically: true, encoding: .utf8)

        // Create subdirectory with xcodeproj (simulating Services/Services.xcodeproj)
        let subDir = tempDir.appendingPathComponent("Services")
        let xcodeprojDir = subDir.appendingPathComponent("Services.xcodeproj")
        let xcodeprojSpmDir = xcodeprojDir
            .appendingPathComponent("project.xcworkspace")
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: xcodeprojSpmDir, withIntermediateDirectories: true)
        let xcodeprojResolved = xcodeprojSpmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: xcodeprojResolved, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        let result = try locator.locate(from: subDir.path)
        #expect(result == xcworkspaceResolved.path)
    }
}
