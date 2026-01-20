import Foundation

/// Represents a parsed Package.swift manifest
public struct PackageManifest: Sendable {
    public let dependencies: [ManifestDependency]

    public init(dependencies: [ManifestDependency]) {
        self.dependencies = dependencies
    }
}

/// Represents a dependency declaration in Package.swift
public struct ManifestDependency: Sendable, Equatable {
    public let url: String
    public let requirement: VersionRequirement

    public init(url: String, requirement: VersionRequirement) {
        self.url = url
        self.requirement = requirement
    }

    /// Normalized identity derived from URL (matches Package.resolved identity)
    public var identity: String {
        // Extract repo name from URL, lowercased
        let name = url
            .replacingOccurrences(of: ".git", with: "")
            .split(separator: "/")
            .last
            .map(String.init) ?? url
        return name.lowercased()
    }
}

/// Version requirement types from Package.swift
public enum VersionRequirement: Sendable, Equatable {
    /// .package(url: "...", from: "1.0.0") or .upToNextMajor(from: "1.0.0")
    case upToNextMajor(from: SemanticVersion)

    /// .upToNextMinor(from: "1.0.0")
    case upToNextMinor(from: SemanticVersion)

    /// .exact("1.0.0")
    case exact(SemanticVersion)

    /// "1.0.0"..<"2.0.0"
    case range(from: SemanticVersion, to: SemanticVersion)

    /// .branch("main")
    case branch(String)

    /// .revision("abc123")
    case revision(String)

    /// Could not determine requirement
    case unknown

    /// Check if a version satisfies this requirement
    public func isSatisfied(by version: SemanticVersion) -> Bool {
        switch self {
        case .upToNextMajor(let from):
            return version.major == from.major && version >= from

        case .upToNextMinor(let from):
            return version.major == from.major &&
                   version.minor == from.minor &&
                   version >= from

        case .exact(let required):
            return version.major == required.major &&
                   version.minor == required.minor &&
                   version.patch == required.patch

        case .range(let lower, let upper):
            return version >= lower && version < upper

        case .branch, .revision, .unknown:
            return true // Can't determine, assume satisfied
        }
    }

    /// Human-readable description
    public var description: String {
        switch self {
        case .upToNextMajor(let from):
            return "from: \(from) (up to next major)"
        case .upToNextMinor(let from):
            return "from: \(from) (up to next minor)"
        case .exact(let version):
            return "exact: \(version)"
        case .range(let from, let to):
            return "\(from)..<\(to)"
        case .branch(let name):
            return "branch: \(name)"
        case .revision(let rev):
            return "revision: \(rev.prefix(7))"
        case .unknown:
            return "unknown"
        }
    }
}
