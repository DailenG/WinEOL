function Get-Win11EOL {
    <#
    .SYNOPSIS
        Retrieves lifecycle information for Microsoft Windows 11.

    .DESCRIPTION
        A wrapper for Get-WinEOL specifically targeting 'windows-11'.
        Allows easy filtering by edition (Home, Pro, Enterprise, etc.) and Status.

    .PARAMETER Pro
        Filter for Pro edition.

    .PARAMETER HomeEdition
        Filter for Home edition.

    .PARAMETER Enterprise
        Filter for Enterprise edition.

    .PARAMETER Education
        Filter for Education edition.

    .PARAMETER IoT
        Filter for IoT Enterprise edition.

    .PARAMETER Version
        Filter by version/feature release (e.g., '25H2', '24H2', '23H2'). Supports wildcards.

    .PARAMETER Status
        Filter results by status: 'All', 'Active', 'EOL', 'NearEOL'.

    .EXAMPLE
        Get-Win11EOL -Pro -Status Active
        Returns currently supported Windows 11 Pro versions.

    .EXAMPLE
        Get-Win11EOL -Version 25H2
        Returns all Windows 11 25H2 versions (Pro and Enterprise).

    .RELATEDLINKS
        https://deepwiki.com/DailenG/WinEOL
    #>
    [CmdletBinding()]
    param(
        [switch]$Pro,
        [Alias('Home')]
        [switch]$HomeEdition,
        [switch]$Enterprise,
        [switch]$Education,
        [switch]$IoT,
        [string]$Version,
        [string]$Status = 'All'
    )

    $params = @{
        ProductName = 'windows-11'
        Status      = $Status
    }

    if ($Version) { $params.Version = $Version }
    if ($Pro) { $params.Pro = $true }
    if ($HomeEdition) { $params.Home = $true }
    if ($Enterprise) { $params.Enterprise = $true }
    if ($Education) { $params.Education = $true }
    if ($IoT) { $params.IoT = $true }

    Get-WinEOL @params
}
