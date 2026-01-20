import Foundation
import XcodeProj

/// Parses .xcodeproj files to extract SPM dependency version requirements
public struct XcodeprojParser: Sendable {
    public init() {}

    /// Parse an Xcode project file for SPM dependencies
    /// - Parameter xcodeprojPath: Path to the .xcodeproj directory
    /// - Returns: Parsed manifest with dependencies
    public func parse(from xcodeprojPath: String) throws -> PackageManifest {
        let xcodeproj = try XcodeProj(pathString: xcodeprojPath)
        let pbxproj = xcodeproj.pbxproj

        guard let project = pbxproj.rootObject else {
            return PackageManifest(dependencies: [])
        }

        var dependencies: [ManifestDependency] = []

        for package in project.remotePackages {
            guard let url = package.repositoryURL else { continue }

            let requirement = mapRequirement(package.versionRequirement)
            dependencies.append(ManifestDependency(url: url, requirement: requirement))
        }

        return PackageManifest(dependencies: dependencies)
    }

    /// Map XcodeProj's version requirement to our VersionRequirement type
    private func mapRequirement(_ requirement: XCRemoteSwiftPackageReference.VersionRequirement?) -> VersionRequirement {
        guard let requirement else { return .unknown }

        switch requirement {
        case .upToNextMajorVersion(let version):
            if let semver = SemanticVersion.parse(version) {
                return .upToNextMajor(from: semver)
            }
            return .unknown

        case .upToNextMinorVersion(let version):
            if let semver = SemanticVersion.parse(version) {
                return .upToNextMinor(from: semver)
            }
            return .unknown

        case .exact(let version):
            if let semver = SemanticVersion.parse(version) {
                return .exact(semver)
            }
            return .unknown

        case .range(from: let from, to: let to):
            if let fromVersion = SemanticVersion.parse(from),
               let toVersion = SemanticVersion.parse(to) {
                return .range(from: fromVersion, to: toVersion)
            }
            return .unknown

        case .branch(let branchName):
            return .branch(branchName)

        case .revision(let rev):
            return .revision(rev)
        }
    }
}

/// Locates .xcodeproj directory relative to a Package.resolved path
public struct XcodeprojLocator: Sendable {
    public init() {}

    /// Find .xcodeproj given a Package.resolved path
    /// - Parameter resolvedPath: Path to Package.resolved
    /// - Returns: Path to .xcodeproj directory if found
    public func locate(fromResolvedPath resolvedPath: String) -> String? {
        let fileManager = FileManager.default

        // Package.resolved in Xcode projects is typically at:
        // .xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
        // or
        // .xcworkspace/xcshareddata/swiftpm/Package.resolved

        var currentPath = (resolvedPath as NSString).deletingLastPathComponent

        // Walk up the directory tree looking for .xcodeproj
        for _ in 0..<10 { // Limit search depth
            // Check if current path is an xcodeproj
            if currentPath.hasSuffix(".xcodeproj") && fileManager.fileExists(atPath: currentPath) {
                return currentPath
            }

            // Check for xcodeproj in current directory
            if let contents = try? fileManager.contentsOfDirectory(atPath: currentPath) {
                for item in contents {
                    if item.hasSuffix(".xcodeproj") {
                        let xcodeprojPath = (currentPath as NSString).appendingPathComponent(item)
                        var isDirectory: ObjCBool = false
                        if fileManager.fileExists(atPath: xcodeprojPath, isDirectory: &isDirectory),
                           isDirectory.boolValue {
                            return xcodeprojPath
                        }
                    }
                }
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
