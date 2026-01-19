import ArgumentParser
import Foundation
import SwiftOutdatedCore

@main
struct SwiftOutdated: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-outdated",
        abstract: "Check for outdated Swift package dependencies",
        discussion: """
            Scans Package.resolved files to find dependencies that have newer versions available.

            By default, searches for Package.resolved in the current directory or within
            Xcode project/workspace directories.
            """,
        version: "1.0.0"
    )

    @Flag(name: .long, help: "Output results in JSON format")
    var json: Bool = false

    @Flag(name: .long, help: "Show all dependencies, not just outdated ones")
    var all: Bool = false

    @Flag(name: .shortAndLong, help: "Print the path of the Package.resolved file being used")
    var verbose: Bool = false

    @Argument(help: "Path to directory, .xcodeproj, .xcworkspace, or Package.resolved file")
    var path: String?

    func run() async throws {
        let searchPath = path ?? FileManager.default.currentDirectoryPath

        // Locate Package.resolved
        let locator = ResolvedFileLocator()
        let resolvedPath: String
        do {
            resolvedPath = try locator.locate(from: searchPath)
        } catch let error as PackageResolvedError {
            throw ValidationError(error.localizedDescription)
        }

        if verbose {
            print("Using: \(resolvedPath)\n")
        }

        // Parse Package.resolved
        let resolved: PackageResolved
        do {
            resolved = try PackageResolved.parse(from: resolvedPath)
        } catch let error as PackageResolvedError {
            throw ValidationError(error.localizedDescription)
        }

        // Convert pins to dependencies
        let dependencies = resolved.pins.map { Dependency.from(pin: $0) }

        if dependencies.isEmpty {
            print("No dependencies found in Package.resolved")
            return
        }

        // Check for updates
        let checker = VersionChecker()
        let checkedDependencies = await checker.checkForUpdates(dependencies)

        // Output results
        let output = ConsoleOutput()
        if json {
            do {
                let jsonOutput = try output.formatJSON(checkedDependencies, showAll: all)
                print(jsonOutput)
            } catch {
                throw ValidationError("Failed to format output as JSON")
            }
        } else {
            print(output.formatTable(checkedDependencies, showAll: all))
        }
    }
}
