# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Optionally allow web lookup of title names via the new `-AllowWebLookup` parameter (#3).
- Provide helpful user suggestions when title names cannot be resolved (#4).
- Exit early if not on Windows (#5).

### Changed

- Improve documentation, examples, and usage information (#3).
- Configure PSScriptAnalyzer GitHub workflow to perform static code analysis of pull requests and pushes (#2).
- Configure compatibility matrix GitHub workflow to perform quick compatibility checks of pull requests and pushes by executing the script using different builds of PowerShell (#2).

### Removed

- Remove `Position` from `-Help` switch parameter to prevent unintended positional binding (#3).
  - This improves clarity and aligns with PowerShell best practices for switch parameters.
  - Positional invocation of `-Help` is no longer supported.

### Fixed

- Add Rugby League Live (ID: `484507D3`) to the built-in title cache (#6).

## [1.2.0] - 2025-08-06

### Added

- Display title names for recovered keys (covers most *Games for Windows* titles).
- Introduce [CHANGELOG.md](./CHANGELOG.md) file to document changes.
- Add [NOTICE](./NOTICE) file to summarize licensing and provide attribution.

### Changed

- Improve parameter validation for all script and function parameters.
- Enhance error handling and verbose output.
- Update documentation and help messaging.

## [1.1.0] - 2025-08-01

### Added

- Initial release: recover product keys from previously activated *Games for Windows LIVE* titles.

[unreleased]: https://github.com/elusiveeagle/recover-gfwl-keys/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/elusiveeagle/recover-gfwl-keys/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/elusiveeagle/recover-gfwl-keys/releases/tag/v1.1.0
