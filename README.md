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

### Download from GitHub Releases

Download the latest binary from the [Releases](https://github.com/diogot/swift-outdated/releases) page:

```bash
curl -L https://github.com/diogot/swift-outdated/releases/latest/download/swift-outdated -o /usr/local/bin/swift-outdated
chmod +x /usr/local/bin/swift-outdated
```

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
| Package   | Current | Latest |
|-----------|---------|--------|
| alamofire | 5.8.0   | 5.10.0 |  <- green (can auto-update)
| xcodeproj | 8.27.7  | 9.7.2  |  <- red (requires manual update)

Blocked updates:
  xcodeproj: from: 8.0.0 (up to next major) (MyApp)
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
    "canAutoUpdate": true,
    "currentVersion": "5.8.0",
    "latestVersion": "5.10.0",
    "package": "alamofire",
    "repositoryURL": "https://github.com/Alamofire/Alamofire.git"
  },
  {
    "canAutoUpdate": false,
    "currentVersion": "8.27.7",
    "latestVersion": "9.7.2",
    "package": "xcodeproj",
    "repositoryURL": "https://github.com/tuist/XcodeProj.git"
  }
]
```

## Requirements

- macOS 13+
- Swift 6.0+

## Contributing

### Version Management

The version is managed via the `VERSION` file at the project root. Before creating a release:

1. Update the `VERSION` file with the new version number
2. Commit and push to `main`
3. Trigger the Release workflow manually from GitHub Actions

## Acknowledgments

This project was inspired by [swift-outdated](https://github.com/kiliankoe/swift-outdated) by Kilian Koeltzsch.

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
