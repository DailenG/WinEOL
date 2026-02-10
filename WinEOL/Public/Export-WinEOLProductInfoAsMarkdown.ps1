function Export-WinEOLProductInfoAsMarkdown {
    <#
    .SYNOPSIS
        Converts product information to Markdown.

    .DESCRIPTION
        This function takes a product information PSObject and converts it to a formatted Markdown document.

    .PARAMETER ProductInfo
        The product information in PSObject format to convert to Markdown.

    .PARAMETER OutputPath
        The directory path where the Markdown file will be saved. The file will be named based on the product name, replacing spaces with underscores.

    .EXAMPLE
        $windowsInfo | Export-WinEOLProductInfoAsMarkdown -OutputPath "C:\ProductInfo"

    .NOTES

    .OUTPUTS
        Markdown file saved to the specified OutputPath.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({
                'WinEOL.ProductInfoWithReleases' -in $_.PSTypeNames
            })]
        [PSObject]$ProductInfo,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path -Path $_ )) {
                    throw "The directory path '$_' does not exist. Please create the directory first."
                }
                else {
                    $True
                }
            })]
        [string]$OutputPath
    )

    process {
        # Build Path for Markdown output
        $MarkdownOutputPath = Join-Path -Path $OutputPath -ChildPath "$($ProductInfo.name.replace(" ","_")).md"

        # Create markdown output
        $markdown = [System.Text.StringBuilder]::new()

        # Product header
        [void]$markdown.AppendLine("# $($ProductInfo.label) ($($ProductInfo.name))")
        [void]$markdown.AppendLine()

        # Date Information was generated
        [void]$markdown.AppendLine("**Page Generated on:** $(Get-Date -Format 'dd MMMM yyyy')")
        [void]$markdown.AppendLine()

        # Releases
        if ($ProductInfo.releases -and $ProductInfo.releases.Count -gt 0) {
            [void]$markdown.AppendLine("## Releases")
            [void]$markdown.AppendLine()

            if ($ProductInfo.links.releasePolicy) {
                [void]$markdown.AppendLine("**Release Policy:** [$($ProductInfo.links.releasePolicy)]($($ProductInfo.links.releasePolicy))")
                [void]$markdown.AppendLine()
            }

            [void]$markdown.AppendLine("| Release | Released | Active Support End | Security Support End | Status | Latest |")
            [void]$markdown.AppendLine("|---------|--------------|-------------------|---------------------|--------|------|")

            foreach ($release in $ProductInfo.releases) {
                $status = "Maintained"
                if ($release.isEol) { $status = "End of Life" }
                elseif ($release.isEoas) { $status = "Security Only" }
                elseif ($release.isLts) { $status = "LTS" }

                # Latest Link and Date
                $latestLinkInfo = "[$($release.latest.name)]($($release.latest.link)) - ($($release.latest.date))"

                [void]$markdown.AppendLine("| $($release.label) | $($release.releaseDate) | $($release.eoasFrom) | $($release.eolFrom) | $status | $latestLinkInfo |")
            }

            [void]$markdown.AppendLine()
        }

        # Version Command
        if ($ProductInfo.versionCommand) {
            [void]$markdown.AppendLine("## Version Command")
            [void]$markdown.AppendLine()
            [void]$markdown.AppendLine("**Command to check current version installed on system:**")
            [void]$markdown.AppendLine()
            [void]$markdown.AppendLine('```')
            [void]$markdown.AppendLine($ProductInfo.versionCommand)
            [void]$markdown.AppendLine('```')
            [void]$markdown.AppendLine()
        }

        # Identifiers
        if ($ProductInfo.identifiers -and $ProductInfo.identifiers.Count -gt 0) {
            [void]$markdown.AppendLine("## Identifiers")
            [void]$markdown.AppendLine()
            [void]$markdown.AppendLine("> **Note:** Not all packages will have a corresponding page, so some links may not work.")
            [void]$markdown.AppendLine()
            [void]$markdown.AppendLine("| Type | ID |")
            [void]$markdown.AppendLine("|------|-----|")

            foreach ($identifier in $ProductInfo.identifiers) {

                # Change link based on OS
                if ($identifier.id -match '^pkg:deb/ubuntu/') {
                    $idParts = $identifier.id -split '/'
                    $idLink = "https://launchpad.net/ubuntu/+source/$($idParts[-1])"
                    [void]$markdown.AppendLine("| $($identifier.type) | [$($identifier.id)]($idLink) |")
                }
                elseif ($identifier.id -match '^pkg:deb/debian/') {
                    $idParts = $identifier.id -split '/'
                    $idLink = "https://sources.debian.org/src/$($idParts[-1])"
                    [void]$markdown.AppendLine("| $($identifier.type) | [$($identifier.id)]($idLink) |")
                }
                elseif ($identifier.id -match '^pkg:rpm/fedora/') {
                    $idParts = $identifier.id -split '/'
                    $idLink = "https://packages.fedoraproject.org/pkgs/$($idParts[-1])"
                    [void]$markdown.AppendLine("| $($identifier.type) | [$($identifier.id)]($idLink) |")
                }
                else {
                    [void]$markdown.AppendLine("| $($identifier.type) | $($identifier.id) |")
                }
            }
        }

        # Output the markdown to file
        $markdown.ToString() | Set-Content -Path $MarkdownOutputPath -Force
    }
}
