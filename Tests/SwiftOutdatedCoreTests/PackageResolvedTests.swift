import Foundation
import Testing
@testable import SwiftOutdatedCore

@Suite("PackageResolved Tests")
struct PackageResolvedTests {

    @Test("Parse v2 format")
    func parseV2Format() throws {
        let json = """
        {
          "pins" : [
            {
              "identity" : "swift-argument-parser",
              "kind" : "remoteSourceControl",
              "location" : "https://github.com/apple/swift-argument-parser.git",
              "state" : {
                "revision" : "c8ed701c513c5b04b1f5f8aeb27de5eb64a6662c",
                "version" : "1.5.0"
              }
            }
          ],
          "version" : 2
        }
        """

        let data = json.data(using: .utf8)!
        let resolved = try PackageResolved.parse(from: data)

        #expect(resolved.version == 2)
        #expect(resolved.pins.count == 1)
        #expect(resolved.pins[0].identity == "swift-argument-parser")
        #expect(resolved.pins[0].kind == "remoteSourceControl")
        #expect(resolved.pins[0].location == "https://github.com/apple/swift-argument-parser.git")
        #expect(resolved.pins[0].state.version == "1.5.0")
        #expect(resolved.pins[0].state.revision == "c8ed701c513c5b04b1f5f8aeb27de5eb64a6662c")
    }

    @Test("Parse v3 format")
    func parseV3Format() throws {
        let json = """
        {
          "originHash" : "abc123",
          "pins" : [
            {
              "identity" : "swift-collections",
              "kind" : "remoteSourceControl",
              "location" : "https://github.com/apple/swift-collections.git",
              "state" : {
                "revision" : "d029d9d39c87bed85b1c50adee7c41f8e6e84e85",
                "version" : "1.1.0"
              }
            }
          ],
          "version" : 3
        }
        """

        let data = json.data(using: .utf8)!
        let resolved = try PackageResolved.parse(from: data)

        #expect(resolved.version == 3)
        #expect(resolved.pins.count == 1)
        #expect(resolved.pins[0].identity == "swift-collections")
        #expect(resolved.pins[0].state.version == "1.1.0")
    }

    @Test("Parse multiple pins")
    func parseMultiplePins() throws {
        let json = """
        {
          "pins" : [
            {
              "identity" : "package-a",
              "kind" : "remoteSourceControl",
              "location" : "https://github.com/example/package-a.git",
              "state" : {
                "revision" : "abc123",
                "version" : "1.0.0"
              }
            },
            {
              "identity" : "package-b",
              "kind" : "remoteSourceControl",
              "location" : "https://github.com/example/package-b.git",
              "state" : {
                "revision" : "def456",
                "version" : "2.3.4"
              }
            }
          ],
          "version" : 2
        }
        """

        let data = json.data(using: .utf8)!
        let resolved = try PackageResolved.parse(from: data)

        #expect(resolved.pins.count == 2)
        #expect(resolved.pins[0].identity == "package-a")
        #expect(resolved.pins[1].identity == "package-b")
    }

    @Test("Parse branch-pinned dependency")
    func parseBranchPinned() throws {
        let json = """
        {
          "pins" : [
            {
              "identity" : "dev-package",
              "kind" : "remoteSourceControl",
              "location" : "https://github.com/example/dev-package.git",
              "state" : {
                "branch" : "main",
                "revision" : "abc123"
              }
            }
          ],
          "version" : 2
        }
        """

        let data = json.data(using: .utf8)!
        let resolved = try PackageResolved.parse(from: data)

        #expect(resolved.pins[0].state.branch == "main")
        #expect(resolved.pins[0].state.version == nil)
    }

    @Test("Invalid JSON throws error")
    func invalidJSONThrows() {
        let invalidJSON = "not valid json"
        let data = invalidJSON.data(using: .utf8)!

        #expect(throws: PackageResolvedError.self) {
            try PackageResolved.parse(from: data)
        }
    }
}
