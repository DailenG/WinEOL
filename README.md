# WinEOL

A Windows-focused PowerShell module that uses the [endoflife.date](https://endoflife.date/) API to report on product support dates, lifecycle status, and release information.

## Features

- **Windows Centric**: Dedicated wrappers for `Windows 11` and `Windows Server`.
- **Smart Filtering**: Filter by Edition (Home/Pro/Enterprise), Status (Active/EOL), or Version.
- **Rich Output**: Returns objects with `Status` (Active, NearEOL, EOL), `DaysRemaining`, and `IsSupported` properties.
- **Caching**: Session-level caching to minimize API calls and improve performance.
- **Wildcard Support**: Easily find products like `windows-*` or `windows-server-2019`.

## Installation

```powershell
Install-Module -Name WinEOL
```

## Usage

### Get-WinEOL

The core function to retrieve product information.

```powershell
# Get info for Windows 11
Get-WinEOL -ProductName "windows-11"

# Search for all Windows products
Get-WinEOL -ProductName "windows-*"

# Get product info filtered by specific status
Get-WinEOL -ProductName "windows-11" -Status Active
```

### Get-Win11EOL

A wrapper specifically for Windows 11 with edition support.

```powershell
# Get all Active Windows 11 Pro releases
Get-Win11EOL -Pro -Status Active

# Get all Enterprise releases
Get-Win11EOL -Enterprise
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

- **Product**: Product Name
- **Cycle**: Version/Cycle
- **ReleaseDate**: Release Date
- **EOL**: The End of Life Date
- **Status**: Active (Green), NearEOL (Yellow), EOL (Red)
- **DaysRemaining**: Days until EOL

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## Credits

Refactored from the [SupportDeathClock](https://github.com/Nibushi/SupportDeathClock) module by **Simon Alexander**.
This project builds upon the original work to provide a Windows-focused experience.

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

