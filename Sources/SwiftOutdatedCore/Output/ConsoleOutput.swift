import Foundation

/// ANSI color codes for terminal output
public enum ANSIColor: String, Sendable {
    case reset = "\u{001B}[0m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"

    public func apply(to string: String) -> String {
        "\(rawValue)\(string)\(ANSIColor.reset.rawValue)"
    }
}

/// Handles formatting and outputting dependency information
public struct ConsoleOutput: Sendable {
    /// Whether to use colors in output (default: true for TTY)
    public let useColors: Bool

    public init(useColors: Bool = isatty(STDOUT_FILENO) != 0) {
        self.useColors = useColors
    }

    /// Format dependencies as a table for console output
    /// - Parameters:
    ///   - dependencies: Array of dependencies to format
    ///   - showAll: If true, show all dependencies; if false, only show outdated ones
    ///   - verbose: If true, show additional details like blocking sources
    /// - Returns: Formatted table string
    public func formatTable(_ dependencies: [Dependency], showAll: Bool = false, verbose: Bool = false) -> String {
        let toDisplay = showAll ? dependencies : dependencies.filter { $0.isOutdated }

        if toDisplay.isEmpty {
            return "All dependencies are up to date!"
        }

        // Calculate column widths
        let nameHeader = "Package"
        let currentHeader = "Current"
        let latestHeader = "Latest"

        let maxNameWidth = max(
            nameHeader.count,
            toDisplay.map { $0.name.count }.max() ?? 0
        )
        let maxCurrentWidth = max(
            currentHeader.count,
            toDisplay.map { $0.currentVersion?.description.count ?? 0 }.max() ?? 0
        )
        let maxLatestWidth = max(
            latestHeader.count,
            toDisplay.map { $0.latestVersion?.description.count ?? 0 }.max() ?? 0
        )

        var lines: [String] = []

        // Header
        let header = "| \(nameHeader.padding(toLength: maxNameWidth, withPad: " ", startingAt: 0)) | \(currentHeader.padding(toLength: maxCurrentWidth, withPad: " ", startingAt: 0)) | \(latestHeader.padding(toLength: maxLatestWidth, withPad: " ", startingAt: 0)) |"
        let separator = "|\(String(repeating: "-", count: maxNameWidth + 2))|\(String(repeating: "-", count: maxCurrentWidth + 2))|\(String(repeating: "-", count: maxLatestWidth + 2))|"

        lines.append(header)
        lines.append(separator)

        // Rows
        for dep in toDisplay {
            let name = dep.name.padding(toLength: maxNameWidth, withPad: " ", startingAt: 0)
            let current = (dep.currentVersion?.description ?? "unknown").padding(toLength: maxCurrentWidth, withPad: " ", startingAt: 0)
            let latestText = dep.latestVersion?.description ?? "unknown"
            let latestPadded = latestText.padding(toLength: maxLatestWidth, withPad: " ", startingAt: 0)

            // Colorize latest version if outdated and we have a version requirement
            let latest: String
            if useColors && dep.isOutdated && dep.versionRequirement != nil {
                if dep.canAutoUpdate {
                    // Green: can be updated automatically (within version requirement)
                    latest = ANSIColor.green.apply(to: latestPadded)
                } else {
                    // Red: requires manual constraint update
                    latest = ANSIColor.red.apply(to: latestPadded)
                }
            } else {
                latest = latestPadded
            }

            lines.append("| \(name) | \(current) | \(latest) |")
        }

        // Add blocked updates footnote (always shown when there are blocked updates)
        let blockedDeps = toDisplay.filter { $0.isOutdated && !$0.canAutoUpdate && !$0.requirementSources.isEmpty }
        if !blockedDeps.isEmpty {
            lines.append("")
            lines.append("Blocked updates:")
            for dep in blockedDeps {
                if let requirement = dep.versionRequirement {
                    let sourceNames = dep.requirementSources.map { formatSourceName($0) }
                    let sourcesText = sourceNames.joined(separator: ", ")
                    lines.append("  \(dep.name): \(requirement.description) (\(sourcesText))")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Format a source path for display (show parent directory for Package.swift files)
    private func formatSourceName(_ path: String) -> String {
        let fileName = (path as NSString).lastPathComponent
        if fileName == "Package.swift" {
            // Show parent directory name for Package.swift files
            let parentPath = (path as NSString).deletingLastPathComponent
            let parentName = (parentPath as NSString).lastPathComponent
            return parentName
        }
        return fileName
    }

    /// Format dependencies as JSON
    /// - Parameters:
    ///   - dependencies: Array of dependencies to format
    ///   - showAll: If true, show all dependencies; if false, only show outdated ones
    /// - Returns: JSON string
    public func formatJSON(_ dependencies: [Dependency], showAll: Bool = false) throws -> String {
        let toDisplay = showAll ? dependencies : dependencies.filter { $0.isOutdated }

        let jsonObjects: [[String: Any]] = toDisplay.map { dep in
            var obj: [String: Any] = [
                "package": dep.name,
                "currentVersion": dep.currentVersion?.description ?? NSNull(),
                "latestVersion": dep.latestVersion?.description ?? NSNull(),
                "repositoryURL": dep.repositoryURL
            ]
            if showAll {
                obj["outdated"] = dep.isOutdated
            }
            if dep.isOutdated && dep.versionRequirement != nil {
                obj["canAutoUpdate"] = dep.canAutoUpdate
            }
            return obj
        }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonObjects, options: [.prettyPrinted, .sortedKeys])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ConsoleOutputError.jsonEncodingFailed
        }
        return jsonString
    }
}

public enum ConsoleOutputError: Error, LocalizedError {
    case jsonEncodingFailed

    public var errorDescription: String? {
        switch self {
        case .jsonEncodingFailed:
            return "Failed to encode dependencies as JSON"
        }
    }
}
