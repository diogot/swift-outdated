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
swift run swift-outdated [--json] [--all] [-v] [path]
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
    │   ├── PackageManifest.swift   # Version requirement types
    │   └── Dependency.swift        # Dependency model + SemanticVersion
    ├── Services/
    │   ├── ResolvedFileLocator.swift    # Find Package.resolved files
    │   ├── PackageManifestParser.swift  # Parse Package.swift for requirements
    │   ├── XcodeprojParser.swift        # Parse .xcodeproj for SPM requirements
    │   ├── GitTagFetcher.swift          # Fetch tags via git ls-remote
    │   └── VersionChecker.swift         # Compare versions
    └── Output/
        └── ConsoleOutput.swift          # Table/JSON formatting with colors
```

## Key Design Decisions

- **Swift 6 Concurrency**: All types are `Sendable` and async operations use structured concurrency
- **Protocol-based Testing**: `GitTagFetching` protocol allows mocking network calls
- **Package.resolved v2/v3**: Supports both formats (v1 is intentionally unsupported)
- **Semantic Versioning**: Full semver parsing including prereleases and build metadata
- **Workspace Priority**: Prefers workspace Package.resolved over xcodeproj to avoid stale files
- **Color Output**: ANSI colors for TTY, auto-disabled for pipes/redirects
- **XcodeProj Support**: Uses XcodeProj library to parse .pbxproj for SPM version requirements

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

# Show all dependencies (not just outdated)
swift-outdated --all

# Verbose mode (show which files are being used)
swift-outdated -v
```

## Color Output

When Package.swift or .xcodeproj is found, the latest version is color-coded:
- **Green**: Can auto-update (latest version satisfies version requirement)
- **Red**: Requires manual update (latest version outside version requirement)

Supported version requirements:
- `from:` / `.upToNextMajor(from:)`
- `.upToNextMinor(from:)`
- `exact:`
- Version ranges (`"1.0.0"..<"2.0.0"`)
- `branch:` / `revision:`

## Testing

Tests use Swift Testing framework (`@Test`, `#expect`). Key test files:

- `PackageResolvedTests.swift` - JSON parsing for v2/v3 formats
- `DependencyTests.swift` - Dependency model and SemanticVersion parsing
- `ResolvedFileLocatorTests.swift` - File location logic with temp directories
- `GitTagFetcherTests.swift` - Mock-based tag fetching tests
- `VersionCheckerTests.swift` - Version comparison and update checking
- `ConsoleOutputTests.swift` - Table and JSON output formatting
- `PackageManifestTests.swift` - Package.swift parsing and version requirement satisfaction
- `XcodeprojParserTests.swift` - XcodeprojLocator file location tests
