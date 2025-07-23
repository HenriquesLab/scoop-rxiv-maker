# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Scoop bucket repository** for rxiv-maker, a Windows package manager distribution. This repository contains the Scoop manifest (`bucket/rxiv-maker.json`) that defines how rxiv-maker is installed via Scoop on Windows systems. It's a git submodule of the main rxiv-maker project and automatically tracks PyPI releases.

## Essential Commands

### Local Testing
```powershell
# Run all tests locally
.\bin\test.ps1

# Run tests in CI mode (verbose output)
.\bin\test.ps1 -CI

# Run specific test file
.\bin\test.ps1 -TestPath "Scoop-Bucket.Tests.ps1"
```

### CI Monitoring
```powershell
# Monitor CI status continuously
.\monitor-ci.ps1

# Check status once and exit
.\monitor-ci.ps1 -Once

# Interactive mode (can cancel hanging jobs)
.\monitor-ci.ps1 -Interactive
```

### Manual Manifest Updates
```powershell
# Test manifest syntax
python -m json.tool bucket/rxiv-maker.json

# Install from local manifest
scoop install ./bucket/rxiv-maker.json --no-cache

# Verify installation
rxiv --version
```

## Repository Architecture

### Core Components
- **`bucket/rxiv-maker.json`** - Main Scoop manifest defining package installation
- **`bin/test.ps1`** - Primary test runner with Pester integration
- **`Scoop-Bucket.Tests.ps1`** - Comprehensive test suite for manifest validation
- **`monitor-ci.ps1`** - CI monitoring and job management tool

### GitHub Actions Workflows
- **`.github/workflows/test-formula.yml`** - Comprehensive testing across Windows versions
- **`.github/workflows/update-formula.yml`** - Automated manifest updates from PyPI

### Testing Infrastructure
- **Manifest validation** - JSON syntax, required fields, URL verification
- **Installation testing** - Multi-Windows version compatibility
- **Performance testing** - CLI startup benchmarks
- **Cache testing** - Scoop cache functionality verification
- **Dependency testing** - Python, Git, Make integration
- **PowerShell compatibility** - Windows PowerShell vs PowerShell Core

## Scoop Manifest Structure

The `bucket/rxiv-maker.json` follows Scoop's manifest schema:

### Key Fields
- **`version`** - Package version (auto-updated from PyPI)
- **`url`** - Download URL for source distribution
- **`hash`** - SHA256 checksum for verification
- **`depends`** - Dependencies (Python required)
- **`suggest`** - Optional dependencies (LaTeX, Git, Make)
- **`bin`** - Command-line shim configuration
- **`post_install`** - pip install commands and verification
- **`pre_uninstall`** - pip uninstall cleanup

### Autoupdate Configuration
- **`checkver`** - PyPI version checking
- **`autoupdate`** - Automatic manifest updates
- Triggered daily via GitHub Actions

## Testing Strategy

### Test Categories
1. **Unit Tests** - Manifest structure validation
2. **Integration Tests** - Scoop installation process
3. **Performance Tests** - Installation timing benchmarks
4. **Compatibility Tests** - Multi-Windows version support
5. **Network Tests** - URL accessibility and PyPI integration

### Test Execution Matrix
- **Syntax-only**: JSON validation and structure checks
- **Quick**: Basic installation on windows-latest
- **Full**: Multi-Windows version testing
- **Comprehensive**: All tests including LaTeX integration

### Test Triggers
- Push to main/develop branches
- Pull requests
- Daily scheduled runs (6 AM UTC)
- Manual workflow dispatch with configurable scope

## Development Workflow

### Making Changes
1. **Edit manifest** - Update `bucket/rxiv-maker.json` as needed
2. **Local testing** - Run `.\bin\test.ps1` to validate changes
3. **Create PR** - GitHub Actions will run comprehensive tests
4. **Monitor CI** - Use `.\monitor-ci.ps1` to track test progress

### Automated Updates
- **Daily checks** - Workflow monitors PyPI for new releases
- **Auto-PR creation** - Creates pull requests for version updates
- **Auto-merge option** - Can be enabled for trusted updates
- **Direct commit mode** - Bypasses PR for automated updates

### Manual Version Updates
```powershell
# Trigger manual update via GitHub Actions
# Use workflow_dispatch with target version parameter
```

## Common Development Tasks

### Debugging Test Failures
1. Check manifest JSON syntax with `python -m json.tool bucket/rxiv-maker.json`
2. Verify PyPI URL accessibility: `curl -I <manifest-url>`
3. Test local installation: `scoop install ./bucket/rxiv-maker.json`
4. Check GitHub Actions logs for detailed error information

### Adding New Tests
- Add test cases to `Scoop-Bucket.Tests.ps1` using Pester framework
- Follow existing patterns for manifest validation
- Include network tests with appropriate error handling
- Test both success and failure scenarios

### Performance Optimization
- Monitor CI run times with `.\monitor-ci.ps1 -Once`
- Use test scope filters (`quick`, `comprehensive`) to balance coverage vs speed
- Cache PowerShell modules and dependencies where possible

## Integration with Main Project

This repository is a **git submodule** of the main rxiv-maker project:
- Located at `git_submodules/scoop-rxiv-maker/` in the parent repository
- Automatically updated when new releases are published
- Maintains independent versioning and release cycle
- Synchronized with PyPI package releases

## Dependencies and Prerequisites

### Required Tools
- **PowerShell 5.1+** or PowerShell Core
- **Scoop package manager** for testing
- **GitHub CLI (gh)** for CI monitoring
- **Pester 5.2.0+** for test execution
- **BuildHelpers 2.0.1+** for test infrastructure

### Python Environment
- **Python 3.11+** automatically installed via Scoop dependency
- **pip** used for rxiv-maker package installation
- **Environment isolation** handled by Scoop's Python shim system

## Troubleshooting

### Common Issues
- **JSON syntax errors**: Use `python -m json.tool` to validate
- **URL accessibility**: Check network connectivity and PyPI status
- **PowerShell execution policy**: Set with `Set-ExecutionPolicy RemoteSigned`
- **Scoop installation**: Ensure Scoop is properly installed and in PATH

### CI Debugging
- Use `.\monitor-ci.ps1 -Interactive` to cancel hanging jobs
- Check workflow dispatch options for targeted testing
- Review GitHub Actions logs for detailed error information
- Test locally before pushing changes

### Performance Issues
- Monitor CI metrics with 7-day performance tracking
- Use appropriate test scopes to optimize run times
- Cache dependencies where possible
- Consider Windows runner limitations