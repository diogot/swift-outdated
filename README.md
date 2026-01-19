# swift-outdated

A CLI tool that checks Swift package dependencies for available updates. Similar to `bundle outdated` for Ruby.

## Features

- Parses `Package.resolved` v2 and v3 formats
- Supports standalone Swift packages and Xcode projects/workspaces
- Fetches latest versions from Git repositories
- Outputs as formatted table or JSON
- Concurrent version checking for fast results

## Installation

### Build from source

```bash
git clone https://github.com/diogo/swift-outdated.git
cd swift-outdated
swift build -c release
cp .build/release/swift-outdated /usr/local/bin/
```

## Usage

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

### Example output

```
| Package                 | Current | Latest |
|-------------------------|---------|--------|
| swift-argument-parser   | 1.2.0   | 1.5.0  |
| swift-collections       | 1.0.0   | 1.1.0  |
```

### JSON output

```json
[
  {
    "package": "swift-argument-parser",
    "currentVersion": "1.2.0",
    "latestVersion": "1.5.0",
    "repositoryURL": "https://github.com/apple/swift-argument-parser.git"
  }
]
```

## Requirements

- macOS 13+
- Swift 6.0+

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
