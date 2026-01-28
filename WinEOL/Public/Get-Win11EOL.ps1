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

    .PARAMETER Status
        Filter results by status: 'All', 'Active', 'EOL', 'NearEOL'.

    .EXAMPLE
        Get-Win11EOL -Pro -Status Active
        Returns currently supported Windows 11 Pro versions.
    #>
    [CmdletBinding()]
    param(
        [switch]$Pro,
        [Alias('Home')]
        [switch]$HomeEdition,
        [switch]$Enterprise,
        [switch]$Education,
        [switch]$IoT,
        [string]$Status = 'All'
    )

    $params = @{
        ProductName = 'windows-11'
        Status      = $Status
    }

    if ($Pro) { $params.Pro = $true }
    if ($HomeEdition) { $params.Home = $true }
    if ($Enterprise) { $params.Enterprise = $true }
    if ($Education) { $params.Education = $true }
    if ($IoT) { $params.IoT = $true }

    Get-WinEOL @params
}
