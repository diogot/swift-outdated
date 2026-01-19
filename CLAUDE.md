# swift-outdated

A CLI tool that checks for outdated Swift package dependencies.

## Build Commands

```bash
# Build the project
swift build

# Build for release
swift build -c release

# Run tests
swift test

# Run a specific test
swift test --filter <TestName>

# Run the CLI
swift run swift-outdated [--json] [path]
```

## Architecture

The project follows a clean separation between the CLI executable and core library:

```
Sources/
├── swift-outdated/           # CLI executable (ArgumentParser-based)
│   └── SwiftOutdated.swift   # Main entry point
└── SwiftOutdatedCore/        # Core library
    ├── Models/
    │   ├── PackageResolved.swift   # Package.resolved v2/v3 parsing
    │   └── Dependency.swift        # Dependency model + SemanticVersion
    ├── Services/
    │   ├── ResolvedFileLocator.swift  # Find Package.resolved files
    │   ├── GitTagFetcher.swift        # Fetch tags via git ls-remote
    │   └── VersionChecker.swift       # Compare versions
    └── Output/
        └── ConsoleOutput.swift        # Table and JSON formatting
```

## Key Design Decisions

- **Swift 6 Concurrency**: All types are `Sendable` and async operations use structured concurrency
- **Protocol-based Testing**: `GitTagFetching` protocol allows mocking network calls
- **Package.resolved v2/v3**: Supports both formats (v1 is intentionally unsupported)
- **Semantic Versioning**: Full semver parsing including prereleases and build metadata

## CLI Usage

```bash
# Check current directory
swift-outdated

# Check specific path
swift-outdated /path/to/project

# Check Xcode project
swift-outdated MyApp.xcodeproj

# Output as JSON
swift-outdated --json
```

## Testing

Tests use Swift Testing framework (`@Test`, `#expect`). Key test files:

- `PackageResolvedTests.swift` - JSON parsing for v2/v3 formats
- `DependencyTests.swift` - Dependency model and SemanticVersion parsing
- `ResolvedFileLocatorTests.swift` - File location logic with temp directories
- `GitTagFetcherTests.swift` - Mock-based tag fetching tests
- `VersionCheckerTests.swift` - Version comparison and update checking
- `ConsoleOutputTests.swift` - Table and JSON output formatting
