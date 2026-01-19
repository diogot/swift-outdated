import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("GitTagFetcher Tests")
struct GitTagFetcherTests {

    @Test("Mock fetcher returns configured tags")
    func mockFetcherReturnsTags() async throws {
        let mockFetcher = MockGitTagFetcher()
        mockFetcher.setTags(["1.0.0", "1.1.0", "2.0.0"], for: "https://github.com/example/repo.git")

        let tags = try await mockFetcher.fetchTags(from: "https://github.com/example/repo.git")

        #expect(tags == ["1.0.0", "1.1.0", "2.0.0"])
    }

    @Test("Mock fetcher returns empty for unknown repo")
    func mockFetcherReturnsEmptyForUnknown() async throws {
        let mockFetcher = MockGitTagFetcher()

        let tags = try await mockFetcher.fetchTags(from: "https://github.com/unknown/repo.git")

        #expect(tags.isEmpty)
    }

    @Test("Mock fetcher can throw errors")
    func mockFetcherCanThrow() async {
        let mockFetcher = MockGitTagFetcher(shouldFail: true)

        await #expect(throws: GitTagFetcherError.self) {
            try await mockFetcher.fetchTags(from: "https://github.com/example/repo.git")
        }
    }
}

@Suite("GitTagFetcher Integration Tests", .disabled("Requires network access"))
struct GitTagFetcherIntegrationTests {
    let fetcher = GitTagFetcher()

    @Test("Fetch tags from real repository")
    func fetchRealTags() async throws {
        let tags = try await fetcher.fetchTags(from: "https://github.com/apple/swift-argument-parser.git")
        #expect(!tags.isEmpty)
    }
}
