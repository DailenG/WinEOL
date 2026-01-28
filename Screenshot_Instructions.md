# Documentation Screenshots Guide

To update the module documentation with high-quality images, please follow these steps.

## Setup

1. Open your terminal (PowerShell 7 recommended).
2. Import the module:
   ```powershell
   Import-Module ./WinEOL -Force
   ```
3. (Optional) Clear your screen for a clean shot: `Clear-Host`

## Required Screenshots

### 1. Main Output Example
**Target**: `docs/images/wineol_output.png`
**Goal**: Show the colorized output and different statuses.

**Run this command**:
```powershell
Get-WinEOL "windows-11" | Select-Object -First 5
```
*Take a screenshot of the table output.*

### 2. Windows 11 Wrapper
**Target**: `docs/images/win11_example.png` (Optional, can be added to Get-Win11EOL section)
**Goal**: Show edition filtering.

**Run this command**:
```powershell
Get-Win11EOL -Pro -Status Active
```

### 3. Server Example
**Target**: `docs/images/server_example.png` (Optional, can be added to Get-WinServerEOL section)

**Run this command**:
```powershell
Get-WinServerEOL -Status Active | Select-Object -First 5
```

## Saving the Images

1. Save the screenshots in the `docs/images/` folder inside the module root.
2. Use the filenames specified above (`wineol_output.png`, etc.).
3. Commit the new images to the repository.

Once these files exist, the `README.md` (and the PowerShell Gallery page) will automatically display them.
