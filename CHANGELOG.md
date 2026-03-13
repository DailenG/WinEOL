# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-03-13

### Added
- **Windows PowerShell 5.1 support** — module manifest now declares `PowerShellVersion = '5.1'` and `CompatiblePSEditions = @('Desktop', 'Core')`, making the module officially compatible with both Windows PowerShell and PowerShell 7+.
- **TLS 1.2 enforcement** — `WinEOL.psm1` now sets `[Net.ServicePointManager]::SecurityProtocol` to include TLS 1.2 at module load time, ensuring HTTPS API calls succeed on PS5.1 systems that default to TLS 1.0/1.1.

### Changed
- **API calls modernized** — all `Invoke-WebRequest ... | ConvertFrom-Json` patterns replaced with `Invoke-RestMethod`, which handles JSON natively and is more idiomatic PowerShell. Affected files: `Get-WinEOLAllProductInfo.ps1`, `Get-WinEOLAllProductsByCategory.ps1`, `Get-WinEOLAllProductsByTag.ps1`.
- **`-UseBasicParsing` added** to all `Invoke-RestMethod` calls across `Get-WinEOL.ps1` and `Add-ArgumentCompleters.ps1`. This parameter is required on PS5.1 in environments where Internet Explorer is not initialized (e.g. Server Core, automation). It is silently ignored by PS7.
- **Pester tests refactored** for cross-edition compatibility with Pester v5:
  - Removed `InModuleScope` (caused PS7 discovery failures).
  - All mocks now use `-ModuleName WinEOL` to correctly intercept calls from within the module's scope.
  - Test script now strips any installed `WinEOL` copies from `$env:PSModulePath` before importing the local development copy, preventing "Multiple script or manifest modules" errors.
  - Assertions updated for PS5.1 compatibility (e.g. `@($res).Count` instead of `$res.Count`).

## [1.2.5] - 2026-03-10

### Added
- Interactive documentation via [DeepWiki](https://deepwiki.com/DailenG/WinEOL).

## [1.2.4] - 2025-03-01

### Changed
- Removed local caching to simplify logic (credit: /u/vim_vs_emacs).

## [1.2.3] - 2024-12-01

### Added
- Initial release of WinEOL with auto-detection, smart filtering, and rich output objects.
