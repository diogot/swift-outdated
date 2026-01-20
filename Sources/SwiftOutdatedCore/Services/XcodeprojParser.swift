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
            dependencies.append(ManifestDependency(url: url, requirement: requirement, sourcePath: xcodeprojPath))
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

/// Locates .xcworkspace directory relative to a Package.resolved path
public struct WorkspaceLocator: Sendable {
    public init() {}

    /// Find .xcworkspace given a Package.resolved path
    /// - Parameter resolvedPath: Path to Package.resolved
    /// - Returns: Path to .xcworkspace directory if found
    public func locate(fromResolvedPath resolvedPath: String) -> String? {
        let fileManager = FileManager.default

        // Package.resolved in workspaces is typically at:
        // .xcworkspace/xcshareddata/swiftpm/Package.resolved

        var currentPath = (resolvedPath as NSString).deletingLastPathComponent

        // Walk up the directory tree looking for .xcworkspace
        for _ in 0..<10 { // Limit search depth
            // Check if current path is an xcworkspace
            if currentPath.hasSuffix(".xcworkspace") && fileManager.fileExists(atPath: currentPath) {
                return currentPath
            }

            // Check for xcworkspace in current directory
            if let contents = try? fileManager.contentsOfDirectory(atPath: currentPath) {
                for item in contents {
                    if item.hasSuffix(".xcworkspace") {
                        let xcworkspacePath = (currentPath as NSString).appendingPathComponent(item)
                        var isDirectory: ObjCBool = false
                        if fileManager.fileExists(atPath: xcworkspacePath, isDirectory: &isDirectory),
                           isDirectory.boolValue {
                            return xcworkspacePath
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

/// Result of parsing a workspace
public struct WorkspaceParseResult: Sendable {
    public let manifest: PackageManifest
    public let xcodeprojPaths: [String]
    public let swiftPackagePaths: [String]
}

/// Parses .xcworkspace files to extract SPM dependency version requirements from all projects and packages
public struct WorkspaceParser: Sendable {
    public init() {}

    /// Parse an Xcode workspace file for SPM dependencies from all referenced projects and packages
    /// - Parameter workspacePath: Path to the .xcworkspace directory
    /// - Returns: Parse result with manifest and paths of all parsed files
    public func parse(from workspacePath: String) throws -> WorkspaceParseResult {
        let workspace = try XCWorkspace(pathString: workspacePath)
        let workspaceDir = (workspacePath as NSString).deletingLastPathComponent

        // Collect all xcodeproj and Swift package paths from workspace
        var xcodeprojPaths: [String] = []
        var swiftPackagePaths: [String] = []
        collectPaths(from: workspace.data.children, relativeTo: workspaceDir, xcodeprojPaths: &xcodeprojPaths, swiftPackagePaths: &swiftPackagePaths)

        var allDependencies: [ManifestDependency] = []

        // Parse each xcodeproj
        let xcodeprojParser = XcodeprojParser()
        for xcodeprojPath in xcodeprojPaths {
            if let manifest = try? xcodeprojParser.parse(from: xcodeprojPath) {
                mergeDependencies(from: manifest, into: &allDependencies)
            }
        }

        // Parse each Swift package
        let manifestParser = PackageManifestParser()
        for packagePath in swiftPackagePaths {
            if let manifest = try? manifestParser.parse(from: packagePath) {
                mergeDependencies(from: manifest, into: &allDependencies)
            }
        }

        return WorkspaceParseResult(
            manifest: PackageManifest(dependencies: allDependencies),
            xcodeprojPaths: xcodeprojPaths,
            swiftPackagePaths: swiftPackagePaths
        )
    }

    /// Merge dependencies from manifest into allDependencies, combining source paths for duplicates
    private func mergeDependencies(from manifest: PackageManifest, into allDependencies: inout [ManifestDependency]) {
        for dep in manifest.dependencies {
            if let existingIndex = allDependencies.firstIndex(where: { $0.identity == dep.identity }) {
                // Add source paths from this dependency to the existing one
                for sourcePath in dep.sourcePaths {
                    if !allDependencies[existingIndex].sourcePaths.contains(sourcePath) {
                        allDependencies[existingIndex] = allDependencies[existingIndex].addingSourcePath(sourcePath)
                    }
                }
            } else {
                allDependencies.append(dep)
            }
        }
    }

    /// Recursively collect all .xcodeproj and Swift package paths from workspace elements
    private func collectPaths(
        from elements: [XCWorkspaceDataElement],
        relativeTo basePath: String,
        xcodeprojPaths: inout [String],
        swiftPackagePaths: inout [String]
    ) {
        let fileManager = FileManager.default

        for element in elements {
            switch element {
            case .file(let fileRef):
                let resolvedPath = resolvePath(fileRef.location, relativeTo: basePath)

                if resolvedPath.hasSuffix(".xcodeproj") && fileManager.fileExists(atPath: resolvedPath) {
                    xcodeprojPaths.append(resolvedPath)
                } else {
                    // Check if it's a directory containing a Package.swift (Swift package)
                    let packageSwiftPath = (resolvedPath as NSString).appendingPathComponent("Package.swift")
                    if fileManager.fileExists(atPath: packageSwiftPath) {
                        swiftPackagePaths.append(packageSwiftPath)
                    }
                }

            case .group(let group):
                // Resolve group's base path
                let groupBasePath = resolvePath(group.location, relativeTo: basePath)

                // Check if the group itself is a Swift package
                let packageSwiftPath = (groupBasePath as NSString).appendingPathComponent("Package.swift")
                if fileManager.fileExists(atPath: packageSwiftPath) {
                    swiftPackagePaths.append(packageSwiftPath)
                }

                // Recurse into children
                collectPaths(from: group.children, relativeTo: groupBasePath, xcodeprojPaths: &xcodeprojPaths, swiftPackagePaths: &swiftPackagePaths)
            }
        }
    }

    /// Resolve a workspace location to an absolute path
    private func resolvePath(_ location: XCWorkspaceDataElementLocationType, relativeTo basePath: String) -> String {
        switch location {
        case .absolute(let path):
            return path

        case .group(let path), .container(let path):
            // Relative to the workspace/container directory
            if path.isEmpty {
                return basePath
            }
            return (basePath as NSString).appendingPathComponent(path)

        case .current(let path):
            // Relative to current location (self:)
            if path.isEmpty {
                return basePath
            }
            return (basePath as NSString).appendingPathComponent(path)

        case .developer(let path):
            // Relative to developer directory - use Xcode's developer path
            if let developerDir = ProcessInfo.processInfo.environment["DEVELOPER_DIR"] {
                return (developerDir as NSString).appendingPathComponent(path)
            }
            // Fallback to default Xcode location
            return ("/Applications/Xcode.app/Contents/Developer" as NSString).appendingPathComponent(path)

        case .other(_, let path):
            // Unknown schema - try relative path
            if path.isEmpty {
                return basePath
            }
            return (basePath as NSString).appendingPathComponent(path)
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
