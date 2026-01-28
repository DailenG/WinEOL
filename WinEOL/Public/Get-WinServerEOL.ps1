function Get-WinServerEOL {
    <#
    .SYNOPSIS
        Retrieves lifecycle information for Microsoft Windows Server.

    .DESCRIPTION
        A wrapper for Get-WinEOL specifically targeting 'windows-server-*' products.
        Useful for auditing Server OS lifecycle status.

    .PARAMETER Status
        Filter results by status: 'All', 'Active', 'EOL', 'NearEOL'.

    .EXAMPLE
        Get-WinServerEOL -Status NearEOL
        Returns Windows Server versions approaching End of Life.
    #>
    [CmdletBinding()]
    param(
        [string]$Status = 'All'
    )

    Get-WinEOL -ProductName "windows-server-*" -Status $Status
}
