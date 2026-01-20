import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("WorkspaceLocator Tests")
struct WorkspaceLocatorTests {
    let locator = WorkspaceLocator()

    @Test("Locate xcworkspace from Package.resolved in xcworkspace")
    func locateFromXcworkspaceResolved() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let xcworkspaceDir = tempDir.appendingPathComponent("MyApp.xcworkspace")
        let spmDir = xcworkspaceDir
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: spmDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = spmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == xcworkspaceDir.path)
    }

    @Test("Locate xcworkspace in parent directory")
    func locateInParentDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Create xcworkspace
        let xcworkspaceDir = tempDir.appendingPathComponent("MyApp.xcworkspace")
        try FileManager.default.createDirectory(at: xcworkspaceDir, withIntermediateDirectories: true)

        // Create subdirectory with Package.resolved
        let subDir = tempDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = subDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == xcworkspaceDir.path)
    }

    @Test("Returns nil when no xcworkspace found")
    func returnsNilWhenNotFound() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = tempDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == nil)
    }

    @Test("Returns nil for Swift package structure")
    func returnsNilForSwiftPackage() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create Package.swift (Swift package)
        let packageSwift = tempDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        // Create Package.resolved in same directory
        let resolvedPath = tempDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == nil)
    }
}

@Suite("XcodeprojLocator Tests")
struct XcodeprojLocatorTests {
    let locator = XcodeprojLocator()

    @Test("Locate xcodeproj from Package.resolved in xcodeproj")
    func locateFromXcodeprojResolved() throws {
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

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == xcodeprojDir.path)
    }

    @Test("Locate xcodeproj from Package.resolved in xcworkspace")
    func locateFromXcworkspaceResolved() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Create xcworkspace structure
        let xcworkspaceDir = tempDir.appendingPathComponent("MyApp.xcworkspace")
        let spmDir = xcworkspaceDir
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("swiftpm")
        try FileManager.default.createDirectory(at: spmDir, withIntermediateDirectories: true)

        // Create xcodeproj in same directory
        let xcodeprojDir = tempDir.appendingPathComponent("MyApp.xcodeproj")
        try FileManager.default.createDirectory(at: xcodeprojDir, withIntermediateDirectories: true)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = spmDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == xcodeprojDir.path)
    }

    @Test("Returns nil when no xcodeproj found")
    func returnsNilWhenNotFound() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = tempDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == nil)
    }

    @Test("Returns nil for Swift package structure")
    func returnsNilForSwiftPackage() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create Package.swift (Swift package)
        let packageSwift = tempDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        // Create Package.resolved in same directory
        let resolvedPath = tempDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == nil)
    }

    @Test("Locates xcodeproj in parent directory")
    func locatesInParentDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let xcodeprojDir = tempDir.appendingPathComponent("MyApp.xcodeproj")
        try FileManager.default.createDirectory(at: xcodeprojDir, withIntermediateDirectories: true)

        // Create subdirectory with Package.resolved
        let subDir = tempDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resolvedPath = subDir.appendingPathComponent("Package.resolved")
        try "{}".write(to: resolvedPath, atomically: true, encoding: .utf8)

        let result = locator.locate(fromResolvedPath: resolvedPath.path)
        #expect(result == xcodeprojDir.path)
    }
}
