import Foundation

/// Checks for outdated dependencies by comparing current versions with latest available
public struct VersionChecker: Sendable {
    private let tagFetcher: GitTagFetching

    public init(tagFetcher: GitTagFetching = GitTagFetcher()) {
        self.tagFetcher = tagFetcher
    }

    /// Check all dependencies for updates
    /// - Parameter dependencies: Array of dependencies to check
    /// - Returns: Array of dependencies with latest version information populated
    public func checkForUpdates(_ dependencies: [Dependency]) async -> [Dependency] {
        await withTaskGroup(of: Dependency.self) { group in
            for dependency in dependencies {
                group.addTask {
                    await self.checkForUpdate(dependency)
                }
            }

            var results: [Dependency] = []
            for await dependency in group {
                results.append(dependency)
            }

            // Sort by name for consistent output
            return results.sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }

    /// Check a single dependency for updates
    private func checkForUpdate(_ dependency: Dependency) async -> Dependency {
        // If dependency is pinned to a branch, we can't determine latest version
        if dependency.branch != nil {
            return dependency
        }

        do {
            let tags = try await tagFetcher.fetchTags(from: dependency.repositoryURL)
            let latestVersion = findLatestVersion(from: tags)
            return dependency.withLatestVersion(latestVersion)
        } catch {
            // If we can't fetch tags, return dependency unchanged
            return dependency
        }
    }

    /// Find the latest semantic version from a list of tags
    /// - Parameter tags: Array of tag strings
    /// - Returns: The highest semantic version found, or nil if none valid
    public func findLatestVersion(from tags: [String]) -> SemanticVersion? {
        tags
            .compactMap { SemanticVersion.parse($0) }
            .filter { $0.prerelease == nil } // Exclude prereleases from "latest"
            .max()
    }
}
