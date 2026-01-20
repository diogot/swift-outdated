# swift-outdated

A CLI tool that checks Swift package dependencies for available updates. Similar to `bundle outdated` for Ruby.

## Features

- Parses `Package.resolved` v2 and v3 formats
- Supports standalone Swift packages and Xcode projects/workspaces
- **Workspace support**: Parses all projects and Swift packages in a workspace
- Fetches latest versions from Git repositories
- **Color-coded output**: green for auto-updatable, red for manual update required
- **Blocked updates reporting**: Shows which file is blocking each update
- Outputs as formatted table or JSON
- Concurrent version checking for fast results

## Installation

### Build from source

```bash
git clone https://github.com/diogot/swift-outdated.git
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

# Show all dependencies (not just outdated)
swift-outdated --all

# Verbose mode (show which files are being used)
swift-outdated -v
```

### Options

| Option | Description |
|--------|-------------|
| `--json` | Output results in JSON format |
| `--all` | Show all dependencies, not just outdated ones |
| `-v, --verbose` | Print the path of files being used |
| `--version` | Show version |
| `-h, --help` | Show help |

### Example output

```
| Package                 | Current | Latest |
|-------------------------|---------|--------|
| swift-argument-parser   | 1.2.0   | 1.5.0  |  (green - can auto-update)
| swift-nio               | 2.0.0   | 3.0.0  |  (red - requires manual update)

Blocked updates:
  swift-nio: from: 2.0.0 (up to next major) (MyApp.xcodeproj)
```

### Color coding

When `Package.swift` or `.xcodeproj` is found, the latest version column is color-coded:

- **Green**: The update can be applied automatically (within your version constraints)
- **Red**: Requires updating the version constraint in `Package.swift` or `.xcodeproj`

When there are blocked updates, a summary shows which file defines the constraint blocking each update. For workspaces with multiple projects or Swift packages, all sources are listed.

### JSON output

```json
[
  {
    "package": "swift-argument-parser",
    "currentVersion": "1.2.0",
    "latestVersion": "1.5.0",
    "repositoryURL": "https://github.com/apple/swift-argument-parser.git",
    "canAutoUpdate": true
  }
]
```

## Requirements

- macOS 13+
- Swift 6.0+

## Acknowledgments

This project was inspired by [swift-outdated](https://github.com/kiliankoe/swift-outdated) by Kilian Koeltzsch.

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
