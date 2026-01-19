import Foundation

/// Represents the Package.resolved file format (supports v2 and v3)
public struct PackageResolved: Codable, Sendable {
    public let version: Int
    public let pins: [Pin]

    public struct Pin: Codable, Sendable {
        public let identity: String
        public let kind: String
        public let location: String
        public let state: State

        public struct State: Codable, Sendable {
            public let revision: String
            public let version: String?
            public let branch: String?
        }
    }

    enum CodingKeys: String, CodingKey {
        case version
        case pins
        case object // v1 format (deprecated but handled)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)

        // v2 and v3 use "pins" directly at root level
        if container.contains(.pins) {
            pins = try container.decode([Pin].self, forKey: .pins)
        } else {
            // v1 format has pins nested under "object"
            throw PackageResolvedError.unsupportedVersion(version)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(pins, forKey: .pins)
    }

    public init(version: Int, pins: [Pin]) {
        self.version = version
        self.pins = pins
    }
}

public enum PackageResolvedError: Error, LocalizedError {
    case unsupportedVersion(Int)
    case fileNotFound(String)
    case invalidFormat(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "Unsupported Package.resolved version: \(version). Only v2 and v3 are supported."
        case .fileNotFound(let path):
            return "Package.resolved not found at: \(path)"
        case .invalidFormat(let details):
            return "Invalid Package.resolved format: \(details)"
        }
    }
}

extension PackageResolved {
    /// Parse Package.resolved from a file path
    public static func parse(from path: String) throws -> PackageResolved {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        return try parse(from: data)
    }

    /// Parse Package.resolved from raw data
    public static func parse(from data: Data) throws -> PackageResolved {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(PackageResolved.self, from: data)
        } catch let decodingError as DecodingError {
            throw PackageResolvedError.invalidFormat(decodingError.localizedDescription)
        }
    }
}
