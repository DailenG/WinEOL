function Show-WinEOLReleaseInfo {
    <#
    .SYNOPSIS
    Displays the release information for the product (nested view).

    .DESCRIPTION
    This function retrieves and displays the release information for the product.
    It includes details such as version, release date, and any relevant notes.

    .PARAMETER ProductWithReleaseInfo
    The product information in PSObject format that contains release details.

    .EXAMPLE
    PS> Get-WinEOLAllProducts | Where-Object Name -like "*windows*" | Show-WinEOLReleaseInfo
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({
                'WinEOL.ProductInfoWithReleases' -in $_.PSTypeNames
            })]
        [object[]]$ProductWithReleaseInfo
    )

    Begin {}

    Process {
        foreach ($product in $ProductWithReleaseInfo) {
            foreach ($release in $product.releases) {

                # Expand out the latest release information, so all properties are available
                $lastestName = $release.latest.name
                $latestDate = $release.latest.date
                $latestLink = $release.latest.link

                $releaseInfo = [PSCustomObject]@{
                    PSTypeName   = "WinEOL.ProductInfo"
                    ProductName  = $product.name
                    ProductLabel = $product.label
                    Name         = $release.name
                    codename     = $release.codename
                    label        = $release.label
                    ReleaseDate  = $release.releaseDate
                    isLts        = $release.isLts
                    ltsFrom      = $release.ltsFrom
                    isEoas       = $release.isEoas
                    eoasFrom     = $release.eoasFrom
                    isEol        = $release.isEol
                    eolFrom      = $release.eolFrom
                    isMaintained = $release.isMaintained
                    latestName   = $lastestName
                    latestDate   = $latestDate
                    latestLink   = $latestLink
                }
                
                # Add calculated properties for compatibility with new format
                $eolDate = $null
                $days = 0
                $statusStr = "Active"
                if ($release.eol -as [DateTime]) {
                    $eolDate = [DateTime]$release.eol
                    $days = ($eolDate - (Get-Date)).Days
                    if ($days -lt 0) { $statusStr = "EOL" }
                    elseif ($days -le 60) { $statusStr = "NearEOL" }
                }
                $releaseInfo | Add-Member -NotePropertyName "DaysRemaining" -NotePropertyValue $days
                $releaseInfo | Add-Member -NotePropertyName "Status" -NotePropertyValue $statusStr

                $releaseInfo
            }
        }
    }

    End {}
}
