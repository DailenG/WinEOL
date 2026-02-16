# WinEOL

A Windows-focused PowerShell module that uses the [endoflife.date](https://endoflife.date/) API to report on product support dates, lifecycle status, and release information.

## Features

- **Windows Centric**: Dedicated wrappers for `Windows 11` and `Windows Server`.
- **Auto-Detection**: Running without parameters automatically detects the current system's OS (Client/Server), Version, and Edition to return relevant EOL info.
- **List Available**: Use `-ListAvailable` to see all supported products.
- **Smart Filtering**: Filter by Edition (Home/Pro/Enterprise), Status (Active/EOL), or Version.
- **Rich Output**: Returns objects with `Status` (Active, NearEOL, EOL), `DaysRemaining`, and `IsSupported` properties.
- **Wildcard Support**: Easily find products like `windows-*` or `windows-server-2019`.

## Installation

```powershell
Install-Module -Name WinEOL
```

## Usage

### Get-WinEOL

The core function to retrieve product information.

```powershell
# Automatically detect and retrieve EOL info for the current system
Get-WinEOL

# List all available products support by the API
Get-WinEOL -ListAvailable

# Get info for Windows 11
Get-WinEOL -ProductName "windows-11"

# Search for all Windows products
Get-WinEOL -ProductName "windows-*"

# Get product info filtered by specific status
Get-WinEOL -ProductName "windows-11" -Status Active

# Filter by version/feature release
Get-WinEOL -ProductName "windows-11" -Version "25H2"
```

### Get-Win11EOL

A wrapper specifically for Windows 11 with edition support.

```powershell
# Get all Active Windows 11 Pro releases
Get-Win11EOL -Pro -Status Active

# Get all Enterprise releases
Get-Win11EOL -Enterprise

# Filter by version
Get-Win11EOL -Version "25H2"
Get-Win11EOL -Pro -Version "24H2" -Status Active
```

### Get-Win11ProEOL

A convenience wrapper for Windows 11 Pro editions.

```powershell
# Get all Windows 11 Pro releases
Get-Win11ProEOL

# Get only active Pro releases
Get-Win11ProEOL -Status Active

# Get specific version
Get-Win11ProEOL -Version "25H2"
```

### Get-WinServerEOL

A wrapper for Windows Server versions.

```powershell
# Get all Windows Server versions
Get-WinServerEOL

# Show only supported Server versions
Get-WinServerEOL -Status Active
```

### Output

The module returns `WinEOL.ProductInfo` objects with the following properties (default view):

![WinEOL Output Example](docs/images/wineol_output.png)

```text
Product             Cycle     ReleaseDate EOL        Status   DaysLeft Latest
-------             -----     ----------- ---        ------   -------- ------
windows-11          24H2      10/01/2024  10/13/2026 Active        610 26100.1
windows-10          22H2      10/18/2022  10/14/2025 Active        246 19045.5
windows-server      2022      08/18/2021  10/13/2031 Active       2436 20348.2
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## Credits

Refactored from the [SupportDeathClock](https://github.com/Nibushi/SupportDeathClock) module by **Simon Alexander**.
This project builds upon the original work to provide a Windows-focused experience.

Special thanks to the Reddit PowerShell community for their feedback and contributions:
- **/u/BlackV** for suggesting output improvements.
- **/u/vim_vs_emacs** for suggesting the removal of local caching to simplify logic.

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

