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

        // Check for .xcodeproj directories and search inside them
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
                if item.hasSuffix(".xcworkspace") {
                    let xcworkspacePath = (searchDirectory as NSString).appendingPathComponent(item)
                    let resolvedPath = (xcworkspacePath as NSString).appendingPathComponent(
                        "xcshareddata/swiftpm/Package.resolved"
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
