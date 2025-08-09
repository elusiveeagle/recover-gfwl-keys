# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2025-08-09

### Added

- Introduce optional web lookup for title names via the new `-AllowWebLookup` parameter ([#3]).
- Provide user-friendly suggestions when title names cannot be resolved ([#4]).
- Exit early on non-Windows platforms ([#5]).

### Changed

- Enhance documentation, examples, and usage information ([#3]).
- Add PSScriptAnalyzer static code analysis to the GitHub Actions workflow for pull requests and pushes ([#2]).
- Add compatibility‐matrix checks to the GitHub Actions workflow, executing the script across different PowerShell versions ([#2]).

### Removed

- Remove the `Position` attribute from the `-Help` switch parameter to prevent unintended positional binding ([#3]).
  - Aligns with PowerShell best practices and disallows positional invocation of `-Help`.

### Fixed

- Fix omission of Rugby League Live (ID: `484507D3`) in the built-in title cache ([#6]).
  - It was previously only tagged for Xbox 360 in the Dbox data.
- Address `PSAvoidUsingWriteHost` rule violation in results summary message ([#7]).

## [1.2.0] - 2025-08-06

### Added

- Display title names for recovered keys (covers most *Games for Windows* titles) ([#1]).
- Introduce [CHANGELOG.md](./CHANGELOG.md) file to document changes ([#1]).
- Add [NOTICE](./NOTICE) file to summarize licensing and provide attribution ([#1]).

### Changed

- Improve parameter validation for all script and function parameters ([#1]).
- Enhance error handling and verbose output ([#1]).
- Update documentation and help messaging ([#1]).

## [1.1.0] - 2025-08-01

### Added

- Initial release: recover product keys from previously activated *Games for Windows LIVE* titles.

[#1]: https://github.com/elusiveeagle/recover-gfwl-keys/pull/1
[#2]: https://github.com/elusiveeagle/recover-gfwl-keys/pull/2
[#3]: https://github.com/elusiveeagle/recover-gfwl-keys/pull/3
[#4]: https://github.com/elusiveeagle/recover-gfwl-keys/pull/4
[#5]: https://github.com/elusiveeagle/recover-gfwl-keys/pull/5
[#6]: https://github.com/elusiveeagle/recover-gfwl-keys/pull/6
[#7]: https://github.com/elusiveeagle/recover-gfwl-keys/pull/7

[unreleased]: https://github.com/elusiveeagle/recover-gfwl-keys/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/elusiveeagle/recover-gfwl-keys/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/elusiveeagle/recover-gfwl-keys/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/elusiveeagle/recover-gfwl-keys/releases/tag/v1.1.0
