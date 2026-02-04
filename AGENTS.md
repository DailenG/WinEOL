# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

WinEOL is a Windows-focused PowerShell module that wraps the [endoflife.date](https://endoflife.date/) API to report on product support dates, lifecycle status, and release information. This is a refactored fork of the original [SupportDeathClock](https://github.com/Nibushi/SupportDeathClock) module, specialized for Windows products.

## Module Structure

This follows standard PowerShell module conventions:
- **WinEOL/WinEOL.psm1**: Root module that dot-sources all functions from Public/ and Private/
- **WinEOL/WinEOL.psd1**: Module manifest defining metadata, PowerShell version requirements (7.0+), and exported functions
- **WinEOL/Public/**: Contains exported cmdlets (Get-WinEOL, Get-Win11EOL, Get-Win11ProEOL, Get-WinServerEOL, etc.)
- **WinEOL/Private/**: Contains internal functions (caching, connection testing, argument completers)
- **WinEOL/formats/**: Custom format files (.ps1xml) defining table views with color-coded status output

The nested `SupportDeathClock/` folder contains the original module and should be ignored or removed during refactoring.

## Core Architecture

### API Integration
All functions call the endoflife.date API (`https://endoflife.date/api/v1/`). The module implements:
- **Session-level caching** (WinEOL.Cache.ps1) to minimize API calls using script-scoped hashtable
- **Smart fallback logic** for complex products like 'windows-11' which redirect to the base 'windows' product and filter results
- **Connection validation** (Test-WinEOLConnection.ps1) that runs during module import

### Data Flow
1. User calls cmdlet (e.g., `Get-Win11EOL -Pro -Status Active`)
2. Wrapper cmdlets build parameters and delegate to `Get-WinEOL`
3. `Get-WinEOL` checks cache, makes API calls if needed, and enriches objects
4. Results are typed as `WinEOL.ProductInfo` with calculated properties:
   - **Status**: "Active", "NearEOL" (<60 days), or "EOL" (past end date)
   - **DaysRemaining**: Days until EOL (negative if already EOL)
   - **IsSupported**: Boolean support status
5. Custom format files apply color-coded table views (Green/Yellow/Red)

### Filtering System
- **Wildcard support**: Product names like `windows-*` fetch all products and recursively call `Get-WinEOL` for matches
- **Version filters**: `-Version` parameter filters by feature release (e.g., `25H2`, `24H2`) matching against the cycle name
- **Edition filters**: `-Pro`, `-HomeEdition`, `-Enterprise`, `-Education`, `-IoT` filter by release name suffix (`*-W` or `*-E`)
- **Status filters**: `-Status Active|EOL|NearEOL|All` filter enriched results

## Key Commands

### Local Development
```powershell
# Import the module locally for testing
Import-Module .\WinEOL\WinEOL.psd1 -Force

# Test specific functions
Get-WinEOL -ProductName "windows-11" -Verbose

# Clear cache during development
Clear-WinEOLCache

# Validate module manifest
Test-ModuleManifest .\WinEOL\WinEOL.psd1
```

### Testing Functions
Basic Pester tests exist in `tests/WinEOL.Tests.ps1`. Manual testing requires:
```powershell
# Test wildcard matching
Get-WinEOL -ProductName "windows-*"

# Test version filtering
Get-Win11EOL -Version "25H2"
Get-Win11ProEOL -Version "24H2" -Status Active

# Test edition filtering
Get-Win11EOL -Pro -Status Active

# Test fallback logic (windows-11 redirects to windows product)
Get-WinEOL -ProductName "windows-11"

# Test caching (second call should be instant)
Measure-Command { Get-WinEOL -ProductName "windows-server" }
Measure-Command { Get-WinEOL -ProductName "windows-server" }

# Run Pester tests
Invoke-Pester -Path .\tests\WinEOL.Tests.ps1
```

### Publishing
```powershell
# Publish to PowerShell Gallery (requires API key)
.\publish.ps1 -ApiKey "your-nuget-api-key"
```

The publish script:
1. Copies root `README.md` to `WinEOL\README.md` (for Gallery display)
2. Runs `Publish-Module` with the provided API key
3. Cleans up the copied README

## Important Patterns

### Adding New Public Functions
1. Create `.ps1` file in `WinEOL/Public/`
2. Include proper comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
3. The root module (`WinEOL.psm1`) auto-discovers and dot-sources all `.ps1` files
4. Functions are auto-exported via `Export-ModuleMember -Function $public.Basename`

### Handling Windows Products
Windows products have complex naming:
- `windows-11` is NOT a product slug in the API; it returns 404
- The API contains `windows` (all releases) and `windows-server` products
- `Get-WinEOL` detects patterns like `windows-(\d+)` and redirects to the `windows` product with cycle filtering
- Windows 11 releases have edition suffixes: `23H2-W` (Home/Pro), `23H2-E` (Enterprise/Education)

### Module Manifest Updates
When adding dependencies or changing exports:
- Update `WinEOL.psd1` `ModuleVersion` (semantic versioning)
- Update `FunctionsToExport` if not using wildcard (currently `'*'`)
- Update `FormatsToProcess` if adding new `.ps1xml` files
- The manifest references the original project URL; update `ProjectUri` to this fork when ready

## Development Notes

- **PowerShell 7.0+ required**: The module targets modern PowerShell with cross-platform capabilities
- **No external dependencies**: Only uses built-in cmdlets (`Invoke-RestMethod`, `Invoke-WebRequest`)
- **Argument completers**: `Add-ArgumentCompleters.ps1` registers tab-completion for product names (dynamically fetched from API)
- **Error handling**: Includes Try/Catch blocks with user-friendly error messages for API failures
- **Refactoring status**: The nested `SupportDeathClock/` folder is legacy code from the original module; focus work on the `WinEOL/` folder

## Development Standards

### Commit Practices: Commit Well, Commit Often
- Make small, atomic commits that represent a single logical change
- Write clear, descriptive commit messages following conventional commit format:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `refactor:` for code restructuring without behavior changes
  - `docs:` for documentation changes
  - `test:` for adding or modifying tests
- Commit after completing each discrete unit of work (e.g., after adding a new function, fixing a bug, updating documentation)
- Include `Co-Authored-By: Warp <agent@warp.dev>` at the end of every commit message
- Never commit secrets, API keys, or sensitive data

### Testing Requirements
This repository currently lacks formal tests. When adding functionality:
- **Write Pester tests** for all new public functions in a `Tests/` directory
- Test structure should mirror module structure: `Tests/Public/Get-WinEOL.Tests.ps1`
- Cover critical paths:
  - API success and failure scenarios
  - Cache behavior (hit/miss)
  - Wildcard matching
  - Edition and status filtering
  - Fallback logic for windows-11/windows-server products
- Mock external API calls using `Mock Invoke-RestMethod` to avoid network dependencies
- Test edge cases: null values, boolean EOL values, missing properties
- Run tests before committing with `Invoke-Pester`

### Best Practices
- **Follow PowerShell approved verbs**: Use `Get-Verb` to validate function names (Get-, Set-, Test-, etc.)
- **Parameter validation**: Use `[ValidateSet()]`, `[ValidateNotNullOrEmpty()]`, and other validation attributes
- **Comment-based help**: Every public function must have complete help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE`
- **Error handling**: Use Try/Catch with meaningful error messages; prefer `Write-Error` over throwing exceptions for user-facing errors
- **Verbose output**: Use `Write-Verbose` for diagnostic information to aid troubleshooting
- **Type safety**: Strongly type parameters and return objects; use PSCustomObject with type names
- **Code formatting**: Use consistent indentation (4 spaces), follow [PowerShell Practice and Style guide](https://poshcode.gitbook.io/powershell-practice-and-style)

### Security Considerations
- **API keys**: The publish.ps1 script accepts API keys as parameters - never hardcode or commit these values
- **Input validation**: Sanitize all user input before passing to API calls or constructing URLs
- **HTTPS only**: All API calls use HTTPS; never downgrade to HTTP
- **Avoid script injection**: Use parameterized approaches; avoid `Invoke-Expression` or dynamic script block construction from user input
- **Secure credential handling**: If adding authentication features, use `[SecureString]` and `[PSCredential]` types
- **Dependency security**: Before adding external module dependencies, audit them for security vulnerabilities
- **Error messages**: Avoid exposing sensitive information (API keys, internal paths, system details) in error messages
