import Foundation

/// Parses Package.swift files to extract dependency version requirements
public struct PackageManifestParser: Sendable {
    public init() {}

    /// Parse a Package.swift file
    /// - Parameter path: Path to Package.swift
    /// - Returns: Parsed manifest with dependencies
    public func parse(from path: String) throws -> PackageManifest {
        let url = URL(fileURLWithPath: path)
        let content = try String(contentsOf: url, encoding: .utf8)
        return parse(content: content)
    }

    /// Parse Package.swift content
    /// - Parameter content: The Package.swift file content
    /// - Returns: Parsed manifest with dependencies
    public func parse(content: String) -> PackageManifest {
        let dependencies = parseDependencies(from: content)
        return PackageManifest(dependencies: dependencies)
    }

    /// Parse all .package() declarations from content
    private func parseDependencies(from content: String) -> [ManifestDependency] {
        var dependencies: [ManifestDependency] = []

        // Pattern to match .package( ... ) declarations
        // This handles multiline declarations
        let packagePattern = #"\.package\s*\([^)]+\)"#

        guard let regex = try? NSRegularExpression(pattern: packagePattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)

        for match in matches {
            guard let matchRange = Range(match.range, in: content) else { continue }
            let declaration = String(content[matchRange])

            if let dependency = parseDependency(from: declaration) {
                dependencies.append(dependency)
            }
        }

        return dependencies
    }

    /// Parse a single .package() declaration
    private func parseDependency(from declaration: String) -> ManifestDependency? {
        // Extract URL
        guard let url = extractURL(from: declaration) else { return nil }

        // Determine requirement type
        let requirement = extractRequirement(from: declaration)

        return ManifestDependency(url: url, requirement: requirement)
    }

    /// Extract URL from declaration
    private func extractURL(from declaration: String) -> String? {
        // Match url: "..." or just the first quoted string that looks like a URL
        let patterns = [
            #"url:\s*"([^"]+)""#,
            #"\"(https?://[^"]+)\""#,
            #"\"(git@[^"]+)\""#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: declaration, range: NSRange(declaration.startIndex..., in: declaration)),
               let urlRange = Range(match.range(at: 1), in: declaration) {
                return String(declaration[urlRange])
            }
        }

        return nil
    }

    /// Extract version requirement from declaration
    private func extractRequirement(from declaration: String) -> VersionRequirement {
        // Check for branch
        if let branch = extractBranch(from: declaration) {
            return .branch(branch)
        }

        // Check for revision
        if let revision = extractRevision(from: declaration) {
            return .revision(revision)
        }

        // Check for exact version
        if let exact = extractExact(from: declaration) {
            return .exact(exact)
        }

        // Check for range (e.g., "1.0.0"..<"2.0.0")
        if let range = extractRange(from: declaration) {
            return range
        }

        // Check for .upToNextMinor
        if let version = extractUpToNextMinor(from: declaration) {
            return .upToNextMinor(from: version)
        }

        // Check for from: or .upToNextMajor (most common)
        if let version = extractFrom(from: declaration) {
            return .upToNextMajor(from: version)
        }

        return .unknown
    }

    private func extractBranch(from declaration: String) -> String? {
        let patterns = [
            #"branch:\s*"([^"]+)""#,
            #"\.branch\s*\(\s*"([^"]+)"\s*\)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: declaration, range: NSRange(declaration.startIndex..., in: declaration)),
               let range = Range(match.range(at: 1), in: declaration) {
                return String(declaration[range])
            }
        }

        return nil
    }

    private func extractRevision(from declaration: String) -> String? {
        let patterns = [
            #"revision:\s*"([^"]+)""#,
            #"\.revision\s*\(\s*"([^"]+)"\s*\)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: declaration, range: NSRange(declaration.startIndex..., in: declaration)),
               let range = Range(match.range(at: 1), in: declaration) {
                return String(declaration[range])
            }
        }

        return nil
    }

    private func extractExact(from declaration: String) -> SemanticVersion? {
        let patterns = [
            #"exact:\s*"([^"]+)""#,
            #"\.exact\s*\(\s*"([^"]+)"\s*\)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: declaration, range: NSRange(declaration.startIndex..., in: declaration)),
               let range = Range(match.range(at: 1), in: declaration) {
                return SemanticVersion.parse(String(declaration[range]))
            }
        }

        return nil
    }

    private func extractRange(from declaration: String) -> VersionRequirement? {
        // Match "1.0.0"..<"2.0.0" or "1.0.0"..."2.0.0"
        let pattern = #""([^"]+)"\s*\.\.[\.<]\s*"([^"]+)""#

        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: declaration, range: NSRange(declaration.startIndex..., in: declaration)),
           let lowerRange = Range(match.range(at: 1), in: declaration),
           let upperRange = Range(match.range(at: 2), in: declaration),
           let lower = SemanticVersion.parse(String(declaration[lowerRange])),
           let upper = SemanticVersion.parse(String(declaration[upperRange])) {
            return .range(from: lower, to: upper)
        }

        return nil
    }

    private func extractUpToNextMinor(from declaration: String) -> SemanticVersion? {
        let pattern = #"\.upToNextMinor\s*\(\s*from:\s*"([^"]+)"\s*\)"#

        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: declaration, range: NSRange(declaration.startIndex..., in: declaration)),
           let range = Range(match.range(at: 1), in: declaration) {
            return SemanticVersion.parse(String(declaration[range]))
        }

        return nil
    }

    private func extractFrom(from declaration: String) -> SemanticVersion? {
        let patterns = [
            #"\.upToNextMajor\s*\(\s*from:\s*"([^"]+)"\s*\)"#,
            #"from:\s*"([^"]+)""#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: declaration, range: NSRange(declaration.startIndex..., in: declaration)),
               let range = Range(match.range(at: 1), in: declaration) {
                return SemanticVersion.parse(String(declaration[range]))
            }
        }

        return nil
    }
}

/// Locates Package.swift relative to a Package.resolved path
public struct PackageSwiftLocator: Sendable {
    public init() {}

    /// Find Package.swift given a Package.resolved path
    /// - Parameter resolvedPath: Path to Package.resolved
    /// - Returns: Path to Package.swift if found
    public func locate(fromResolvedPath resolvedPath: String) -> String? {
        let fileManager = FileManager.default

        // Package.resolved can be in various locations:
        // 1. Same directory as Package.swift (Swift package)
        // 2. .xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
        // 3. .xcworkspace/xcshareddata/swiftpm/Package.resolved

        var currentPath = (resolvedPath as NSString).deletingLastPathComponent

        // Walk up the directory tree looking for Package.swift
        for _ in 0..<10 { // Limit search depth
            let packageSwiftPath = (currentPath as NSString).appendingPathComponent("Package.swift")
            if fileManager.fileExists(atPath: packageSwiftPath) {
                return packageSwiftPath
            }

            let parentPath = (currentPath as NSString).deletingLastPathComponent
            if parentPath == currentPath {
                break // Reached root
            }
            currentPath = parentPath
        }

        return nil
    }
}
