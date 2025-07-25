function Get-SDCProductInfo {
    <#
    .SYNOPSIS
        Retrieves a list of products.

    .DESCRIPTION
        This function fetches a list of products from the endoflife.date API and returns it as a PowerShell object.
        Uses either the /products/{productName} endpoint to retrieve specific product information or the /products/{productName}/releases/latest endpoint to get the latest release information.

    .EXAMPLE
        Get-SDCProductList

    .NOTES
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position=0, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, Position=0, ParameterSetName = 'SpecificRelease')]
        [Parameter(Mandatory = $true, Position=0, ParameterSetName = 'LatestRelease')]
        [string]$ProductName,

        [Parameter(Mandatory = $true, Position=1, ParameterSetName = 'SpecificRelease')]
        [string]$Release,

        [Parameter(Mandatory = $true, ParameterSetName = 'LatestRelease')]
        [switch]$Latest
    )

    if ($Latest) {
        $url = "https://endoflife.date/api/v1/products/$($ProductName)/releases/latest"
        $pstypename = "SupportDeathClock.EOLProductInfo"
    }
    else {
        # If a value is provided for the Release parameter, use it to construct the URL
        if ($PSBoundParameters.ContainsKey('Release') -and -not [string]::IsNullOrWhiteSpace($Release)) {
            $url = "https://endoflife.date/api/v1/products/$($ProductName)/releases/$($Release)"
            $pstypename = "SupportDeathClock.EOLProductInfo"
        } else {
            $url = "https://endoflife.date/api/v1/products/$($ProductName)"
            $pstypename = "SupportDeathClock.EOLProductInfoWithReleases"
        }
    }

    try {
        $product = @(Invoke-WebRequest -Uri $url -Method Get -ErrorAction Stop)

        if ($null -eq $product) {
            Write-Error "No product found with the name '$ProductName'."
            return
        }

        # Convert the JSON response to a PowerShell object
         $product = ($product.Content| ConvertFrom-Json).result

        # Add pstypenames for each product, this will be used for custom formatting and validation
        foreach($p in $product) {
            $p.pstypenames.insert(0, $pstypename)
        }

        Write-Verbose "Product information for '$ProductName' retrieved successfully."

        # Convert the product information to a PowerShell object
        $product
    }
    catch {
        Write-Error "Failed to retrieve product information for '$ProductName'. Error: $_"
        return
    }
}
