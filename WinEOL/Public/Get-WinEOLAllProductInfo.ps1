function Get-WinEOLAllProducts {
    <#
    .SYNOPSIS
        Retrieves a list of all products.

    .DESCRIPTION
        This function fetches a list of all products from the endoflife.date API and returns it as a PowerShell object.
        Calls the /products/full endpoint to retrieve comprehensive product information.

    .EXAMPLE
       Get-WinEOLAllProducts
    #>
    [CmdletBinding()]
    param(
    )

    $url = "https://endoflife.date/api/v1/products/full"

    try {
        $allProducts = Invoke-WebRequest -Uri $url -Method Get -ErrorAction Stop

        if ($null -eq $allProducts) {
            Write-Error "No products found."
            return
        }

        # Convert the JSON response to a PowerShell object
        $allProducts = ($allProducts.Content | ConvertFrom-Json).result

        # Add pstypenames for each product, this will be used for custom formatting and validation
        foreach ($p in $allProducts) {
            $p.pstypenames.insert(0, "WinEOL.ProductInfoWithReleases")
        }

        Write-Verbose "All Product information retrieved successfully."
        $allProducts
    }
    catch {
        Write-Error "Failed to retrieve all product information. Error: $_"
        return
    }
}
