function Show-SDCProductReleaseInfo {
    <#
    .SYNOPSIS
    Displays the release information for the Support Death Clock product.

    .DESCRIPTION
    This function retrieves and displays the release information for the Support Death Clock product.
    It includes details such as version, release date, and any relevant notes.

    .PARAMETER ProductWithReleaseInfo
    The product information in PSObject format that contains release details.

    .EXAMPLE
    PS> Get-SDCProductInfo -ProductName python | Show-SDCProductReleaseInfo

    Displays the release information for the Support Death Clock product.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({
            'SupportDeathClock.EOLProductInfoWithReleases' -in $_.PSTypeNames
        })]
        [object[]]$ProductWithReleaseInfo
    )

    Begin{}

    Process{
        foreach ($product in $ProductWithReleaseInfo) {
            foreach ($release in $product.releases) {

                # Expand out the latest release information, so all properties are available
                $lastestName = $release.latest.name
                $latestDate = $release.latest.date
                $latestLink = $release.latest.link

                $releaseInfo = [PSCustomObject]@{
                    PSTypeName    = "SupportDeathClock.EOLProductReleaseInfo"
                    ProductName   = $product.name
                    ProductLabel  = $product.label
                    Name          = $release.name
                    codename      = $release.codename
                    label         = $release.label
                    ReleaseDate   = $release.releaseDate
                    isLts         = $release.isLts
                    ltsFrom       = $release.ltsFrom
                    isEoas        = $release.isEoas
                    eoasFrom     = $release.eoasFrom
                    isEol         = $release.isEol
                    eolFrom       = $release.eolFrom
                    isMaintained = $release.isMaintained
                    latestName    = $lastestName
                    latestDate    = $latestDate
                    latestLink    = $latestLink
                }

                $releaseInfo
            }
        }
    }

    End{}
}
