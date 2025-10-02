# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.0] - 2025-10-02

### Added
- `multiplatform_setup.sh` with automatic OS/architecture detection
- Support for macOS (ARM64/x86_64) and Linux (Arch-based distributions)
- Force options (`--force-platform` and `--force-arch`) for manual override
- Color-coded output for better user experience
- Snakemake workflow management system to bioinformatics packages
- Multi-platform documentation in README
- `IGNORE/changes.md` for tracking development

### Changed
- Replaced `wget` with `curl` for consistency across all platforms
- Updated README with platform compatibility table and troubleshooting section

### Deprecated
- `arm64_setup.sh` - replaced by `multiplatform_setup.sh` (removed from tracking but kept locally)

## [v1.0] - 2025-04-15

### Added
- `arm64_setup.sh` script to build the setup in ZSH
- installation instructions
- information on the `--fish` parameter to build it in fish
- flowchart for the structure built by the script

### Future Implementations
- script for Ubuntu on x86_64