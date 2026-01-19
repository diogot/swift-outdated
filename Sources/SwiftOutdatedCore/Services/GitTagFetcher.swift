import Foundation

/// Protocol for fetching Git tags from repositories
public protocol GitTagFetching: Sendable {
    func fetchTags(from repositoryURL: String) async throws -> [String]
}

/// Fetches Git tags from remote repositories using `git ls-remote`
public struct GitTagFetcher: GitTagFetching, Sendable {
    public init() {}

    /// Fetch all tags from a remote Git repository
    /// - Parameter repositoryURL: The URL of the Git repository
    /// - Returns: Array of tag names
    public func fetchTags(from repositoryURL: String) async throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["ls-remote", "--tags", "--refs", repositoryURL]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw GitTagFetcherError.fetchFailed(repositoryURL)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        // Parse git ls-remote output
        // Format: <sha>\trefs/tags/<tagname>
        let tags = output.split(separator: "\n").compactMap { line -> String? in
            let parts = line.split(separator: "\t")
            guard parts.count == 2 else { return nil }
            let ref = String(parts[1])
            guard ref.hasPrefix("refs/tags/") else { return nil }
            return String(ref.dropFirst("refs/tags/".count))
        }

        return tags
    }
}

public enum GitTagFetcherError: Error, LocalizedError {
    case fetchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let url):
            return "Failed to fetch tags from: \(url)"
        }
    }
}

/// Mock implementation for testing
public final class MockGitTagFetcher: GitTagFetching, @unchecked Sendable {
    private var tagsPerRepository: [String: [String]]
    private var shouldFail: Bool

    public init(tagsPerRepository: [String: [String]] = [:], shouldFail: Bool = false) {
        self.tagsPerRepository = tagsPerRepository
        self.shouldFail = shouldFail
    }

    public func setTags(_ tags: [String], for repositoryURL: String) {
        tagsPerRepository[repositoryURL] = tags
    }

    public func fetchTags(from repositoryURL: String) async throws -> [String] {
        if shouldFail {
            throw GitTagFetcherError.fetchFailed(repositoryURL)
        }
        return tagsPerRepository[repositoryURL] ?? []
    }
}
