function Get-Win11ProEOL {
    <#
    .SYNOPSIS
        Retrieves lifecycle information for Microsoft Windows 11 Pro edition.

    .DESCRIPTION
        A convenience wrapper for Get-Win11EOL -Pro.
        Returns only Windows 11 Pro edition lifecycle data.

    .PARAMETER Version
        Filter by version/feature release (e.g., '25H2', '24H2', '23H2'). Supports wildcards.

    .PARAMETER Status
        Filter results by status: 'All', 'Active', 'EOL', 'NearEOL'.

    .EXAMPLE
        Get-Win11ProEOL
        Returns all Windows 11 Pro versions.

    .EXAMPLE
        Get-Win11ProEOL -Status Active
        Returns currently supported Windows 11 Pro versions.

    .EXAMPLE
        Get-Win11ProEOL -Version 25H2
        Returns Windows 11 Pro 25H2.
    #>
    [CmdletBinding()]
    param(
        [string]$Version,
        [ValidateSet('All', 'Active', 'EOL', 'NearEOL')]
        [string]$Status = 'All'
    )

    $params = @{
        Pro    = $true
        Status = $Status
    }
    if ($Version) { $params.Version = $Version }

    Get-Win11EOL @params
}
