import Foundation

/// Handles formatting and outputting dependency information
public struct ConsoleOutput: Sendable {
    public init() {}

    /// Format dependencies as a table for console output
    /// - Parameters:
    ///   - dependencies: Array of dependencies to format
    ///   - showAll: If true, show all dependencies; if false, only show outdated ones
    /// - Returns: Formatted table string
    public func formatTable(_ dependencies: [Dependency], showAll: Bool = false) -> String {
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
            let latest = (dep.latestVersion?.description ?? "unknown").padding(toLength: maxLatestWidth, withPad: " ", startingAt: 0)
            lines.append("| \(name) | \(current) | \(latest) |")
        }

        return lines.joined(separator: "\n")
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
