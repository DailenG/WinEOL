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
    }
    else {
        # If a value is provided for the Release parameter, use it to construct the URL
        if ($PSBoundParameters.ContainsKey('Release') -and -not [string]::IsNullOrWhiteSpace($Release)) {
            $url = "https://endoflife.date/api/v1/products/$($ProductName)/releases/$($Release)"
        } else {
            $url = "https://endoflife.date/api/v1/products/$($ProductName)"
        }
    }

    try {
        $product = @(Invoke-RestMethod -Uri $url -ErrorAction Stop)

        if ($null -eq $product) {
            Write-Error "No product found with the name '$ProductName'."
            return
        }

        Write-Verbose "Product information for '$ProductName' retrieved successfully."

        # Convert the product information to a PowerShell object
        $productInfo = [psobject]$product.result
        $productInfo
    }
    catch {
        Write-Error "Failed to retrieve product information for '$ProductName'. Error: $_"
        return
    }
}
