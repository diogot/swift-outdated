import Foundation

/// Represents a dependency with its current and latest version information
public struct Dependency: Sendable, Equatable {
    public let name: String
    public let repositoryURL: String
    public let currentVersion: SemanticVersion?
    public let currentRevision: String
    public let latestVersion: SemanticVersion?
    public let branch: String?
    public let versionRequirement: VersionRequirement?
    public let requirementSources: [String]

    public init(
        name: String,
        repositoryURL: String,
        currentVersion: SemanticVersion?,
        currentRevision: String,
        latestVersion: SemanticVersion? = nil,
        branch: String? = nil,
        versionRequirement: VersionRequirement? = nil,
        requirementSources: [String] = []
    ) {
        self.name = name
        self.repositoryURL = repositoryURL
        self.currentVersion = currentVersion
        self.currentRevision = currentRevision
        self.latestVersion = latestVersion
        self.branch = branch
        self.versionRequirement = versionRequirement
        self.requirementSources = requirementSources
    }

    /// Returns true if the dependency is outdated (latest version > current version)
    public var isOutdated: Bool {
        guard let current = currentVersion, let latest = latestVersion else {
            return false
        }
        return latest > current
    }

    /// Returns true if the latest version can be updated automatically (satisfies version requirement)
    public var canAutoUpdate: Bool {
        guard let latest = latestVersion, let requirement = versionRequirement else {
            return true // If we don't know the requirement, assume it can auto-update
        }
        return requirement.isSatisfied(by: latest)
    }

    /// Returns a new Dependency with the latest version set
    public func withLatestVersion(_ version: SemanticVersion?) -> Dependency {
        Dependency(
            name: name,
            repositoryURL: repositoryURL,
            currentVersion: currentVersion,
            currentRevision: currentRevision,
            latestVersion: version,
            branch: branch,
            versionRequirement: versionRequirement,
            requirementSources: requirementSources
        )
    }

    /// Returns a new Dependency with the version requirement and sources set
    public func withVersionRequirement(_ requirement: VersionRequirement?, sources: [String] = []) -> Dependency {
        Dependency(
            name: name,
            repositoryURL: repositoryURL,
            currentVersion: currentVersion,
            currentRevision: currentRevision,
            latestVersion: latestVersion,
            branch: branch,
            versionRequirement: requirement,
            requirementSources: sources
        )
    }
}

/// Semantic version representation
public struct SemanticVersion: Sendable, Equatable, Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?
    public let buildMetadata: String?

    public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil, buildMetadata: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }

    public var description: String {
        var result = "\(major).\(minor).\(patch)"
        if let prerelease = prerelease {
            result += "-\(prerelease)"
        }
        if let buildMetadata = buildMetadata {
            result += "+\(buildMetadata)"
        }
        return result
    }

    /// Parse a version string into a SemanticVersion
    public static func parse(_ string: String) -> SemanticVersion? {
        var versionString = string

        // Remove leading 'v' or 'V' if present
        if versionString.lowercased().hasPrefix("v") {
            versionString = String(versionString.dropFirst())
        }

        // Split off build metadata
        var buildMetadata: String?
        if let plusIndex = versionString.firstIndex(of: "+") {
            buildMetadata = String(versionString[versionString.index(after: plusIndex)...])
            versionString = String(versionString[..<plusIndex])
        }

        // Split off prerelease
        var prerelease: String?
        if let hyphenIndex = versionString.firstIndex(of: "-") {
            prerelease = String(versionString[versionString.index(after: hyphenIndex)...])
            versionString = String(versionString[..<hyphenIndex])
        }

        // Parse major.minor.patch
        let components = versionString.split(separator: ".")
        guard components.count >= 1,
              let major = Int(components[0]) else {
            return nil
        }

        let minor = components.count >= 2 ? Int(components[1]) ?? 0 : 0
        let patch = components.count >= 3 ? Int(components[2]) ?? 0 : 0

        return SemanticVersion(
            major: major,
            minor: minor,
            patch: patch,
            prerelease: prerelease,
            buildMetadata: buildMetadata
        )
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        // Compare major, minor, patch
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // Prerelease versions have lower precedence than normal versions
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil):
            return false
        case (nil, _):
            return false // lhs is release, rhs is prerelease -> lhs > rhs
        case (_, nil):
            return true  // lhs is prerelease, rhs is release -> lhs < rhs
        case (let lhsPre?, let rhsPre?):
            return lhsPre < rhsPre
        }
    }
}

extension Dependency {
    /// Create a Dependency from a PackageResolved.Pin
    public static func from(pin: PackageResolved.Pin) -> Dependency {
        let version = pin.state.version.flatMap { SemanticVersion.parse($0) }
        return Dependency(
            name: pin.identity,
            repositoryURL: pin.location,
            currentVersion: version,
            currentRevision: pin.state.revision,
            branch: pin.state.branch
        )
    }
}
