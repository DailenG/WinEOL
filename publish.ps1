<#
.SYNOPSIS
    Compiles and Publishes the WinEOL module to the PowerShell Gallery.

.DESCRIPTION
    This script performs the following actions:
    1. Checks for the API key (ApiKey) parameter.
    2. Copies the root README.md to the module folder (WinEOL\README.md) so it appears on the Gallery page.
    3. Runs Publish-Module.
    4. Cleans up the copied README.md.

.PARAMETER ApiKey
    The NuGet API Key for the PowerShell Gallery. Required.

.EXAMPLE
    .\publish.ps1 -ApiKey "your-api-key"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey
)

$ErrorActionPreference = 'Stop'
$moduleName = "WinEOL"
$modulePath = Join-Path $PSScriptRoot $moduleName
$rootReadme = Join-Path $PSScriptRoot "README.md"
$moduleReadme = Join-Path $modulePath "README.md"

Write-Host "Starting publication process for '$moduleName'..." -ForegroundColor Cyan

# 1. Validation
if (-not (Test-Path $rootReadme)) {
    Write-Error "Root README.md not found at $rootReadme"
}

# 2. Copy README to Module path
Write-Host "Copying README.md to module folder..." -ForegroundColor Gray
Copy-Item -Path $rootReadme -Destination $moduleReadme -Force

try {
    # 3. Publish
    Write-Host "Publishing module to PowerShell Gallery..." -ForegroundColor Cyan
    # Note: Validate module first
    # Test-ModuleManifest -Path "$modulePath\$moduleName.psd1"
    
    Publish-Module -Path $modulePath -NuGetApiKey $ApiKey -Verbose
    
    Write-Host "Successfully published $moduleName!" -ForegroundColor Green
}
catch {
    Write-Error "Publishing failed: $_"
}
finally {
    # 4. Cleanup
    if (Test-Path $moduleReadme) {
        Write-Host "Cleaning up module README..." -ForegroundColor Gray
        Remove-Item -Path $moduleReadme -Force
    }
}
