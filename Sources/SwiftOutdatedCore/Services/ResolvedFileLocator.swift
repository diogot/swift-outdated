import Foundation

/// Locates Package.resolved files in various locations
public struct ResolvedFileLocator: Sendable {
    public init() {}

    /// Standard locations to search for Package.resolved relative to a directory
    private static let searchPaths = [
        "Package.resolved",
        ".build/checkouts/Package.resolved",
        // Xcode project locations
        "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    ]

    /// Locate Package.resolved file starting from the given path
    /// - Parameter path: Directory or .xcodeproj path to search from
    /// - Returns: Path to Package.resolved if found
    public func locate(from path: String) throws -> String {
        let fileManager = FileManager.default
        var searchDirectory = path

        // Check if path is a file (Package.resolved directly)
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                // Direct path to Package.resolved
                if path.hasSuffix("Package.resolved") {
                    return path
                }
            }
        }

        // If path is an .xcodeproj, look inside it
        if path.hasSuffix(".xcodeproj") {
            let xcodeProjResolved = (path as NSString).appendingPathComponent(
                "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
            )
            if fileManager.fileExists(atPath: xcodeProjResolved) {
                return xcodeProjResolved
            }
            throw PackageResolvedError.fileNotFound(xcodeProjResolved)
        }

        // If path is an .xcworkspace, look inside it
        if path.hasSuffix(".xcworkspace") {
            let xcworkspaceResolved = (path as NSString).appendingPathComponent(
                "xcshareddata/swiftpm/Package.resolved"
            )
            if fileManager.fileExists(atPath: xcworkspaceResolved) {
                return xcworkspaceResolved
            }
            throw PackageResolvedError.fileNotFound(xcworkspaceResolved)
        }

        // Search for Package.resolved in standard locations
        searchDirectory = path

        // First, check for direct Package.resolved
        let directPath = (searchDirectory as NSString).appendingPathComponent("Package.resolved")
        if fileManager.fileExists(atPath: directPath) {
            return directPath
        }

        // Search for .xcworkspace in current directory and parent directories
        // Workspaces are preferred over .xcodeproj as they represent the top-level project
        var currentDir = searchDirectory
        while true {
            if let contents = try? fileManager.contentsOfDirectory(atPath: currentDir) {
                for item in contents {
                    if item.hasSuffix(".xcworkspace") {
                        let xcworkspacePath = (currentDir as NSString).appendingPathComponent(item)
                        let resolvedPath = (xcworkspacePath as NSString).appendingPathComponent(
                            "xcshareddata/swiftpm/Package.resolved"
                        )
                        if fileManager.fileExists(atPath: resolvedPath) {
                            return resolvedPath
                        }
                    }
                }
            }

            let parentDir = (currentDir as NSString).deletingLastPathComponent
            if parentDir == currentDir {
                break // Reached root
            }
            currentDir = parentDir
        }

        // Fall back to .xcodeproj in current directory only
        if let contents = try? fileManager.contentsOfDirectory(atPath: searchDirectory) {
            for item in contents {
                if item.hasSuffix(".xcodeproj") {
                    let xcodeProjPath = (searchDirectory as NSString).appendingPathComponent(item)
                    let resolvedPath = (xcodeProjPath as NSString).appendingPathComponent(
                        "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
                    )
                    if fileManager.fileExists(atPath: resolvedPath) {
                        return resolvedPath
                    }
                }
            }
        }

        throw PackageResolvedError.fileNotFound(searchDirectory)
    }
}
