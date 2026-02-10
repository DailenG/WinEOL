function Get-WinEOLProductReleaseNumber {
    <#
    .SYNOPSIS
        Retrieves release numbers for a specified product.

    .DESCRIPTION
        The Get-WinEOLProductReleaseNumber function retrieves the release numbers (cycles)
        for a specified product using the Get-WinEOL cmdlet.

    .PARAMETER ProductName
        The name of the product to retrieve release numbers for.

    .EXAMPLE
        Get-WinEOLProductReleaseNumber -ProductName "windows-11"

        Returns release numbers for Windows 11.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProductName
    )

    # Get product information to ensure the product exists
    $productInfo = @(Get-WinEOL -ProductName $ProductName)

    # Create a generic list to hold release information
    $releaseInfo = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($product in $productInfo) {
        $releaseInfo.Add([PSCustomObject]@{
                Release = $product.Cycle
            })
    }

    Write-Verbose "Release information for '$ProductName' retrieved successfully."
    return $releaseInfo
}
