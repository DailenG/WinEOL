function Get-WinEOL {
    <#
    .SYNOPSIS
        Retrieves product EOL information and lifecycle status.

    .DESCRIPTION
        The Get-WinEOL cmdlet fetches product lifecycle data from the endoflife.date API.
        It supports wildcard searching, session-level caching to reduce API load, and rich object output 
        including calculated status (Active, NearEOL, EOL) and days remaining.

        It also includes smart fallback logic for complex products like 'windows-11' that are part of the 'windows' product availability.

    .PARAMETER ProductName
        The name of the product to query (e.g., 'windows-11', 'windows-server-2022'). 
        Supports wildcards (e.g., 'windows-*').

    .PARAMETER Release
        A specific release to query.

    .PARAMETER Latest
        Switch to return only the latest release.

    .PARAMETER Refresh
        Switch to bypass the session cache and force a fresh API call.

    .PARAMETER Pro
        Filter for 'Pro' edition (implies *-W suffix).

    .PARAMETER HomeEdition
        Filter for 'Home' edition (implies *-W suffix). Alias: Home.

    .PARAMETER Enterprise
        Filter for 'Enterprise' edition (implies *-E suffix).

    .PARAMETER Education
        Filter for 'Education' edition (implies *-E suffix).

    .PARAMETER IoT
        Filter for 'IoT' edition (implies *-E suffix).

    .PARAMETER Version
        Filter by version/feature release (e.g., '25H2', '24H2', '23H2'). Supports wildcards.
        Filters results where the cycle contains the specified version string.

    .PARAMETER Status
        Filter by lifecycle status. Options: 'All', 'Active', 'EOL', 'NearEOL'. Default is 'All'.

    .EXAMPLE
        Get-WinEOL -ProductName "windows-11"
        Retrieves all Windows 11 release information.

    .EXAMPLE
        Get-WinEOL -ProductName "windows-11" -Version "25H2"
        Retrieves Windows 11 25H2 release information.

    .EXAMPLE
        Get-WinEOL -ProductName "windows-server-*" -Status Active
        Retrieves all active Windows Server versions.

    .EXAMPLE
        Get-WinEOL -ProductName "windows-server-2022" -Latest
        Retrieves the latest Python release info.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string]$ProductName = 'windows-*',

        [Parameter()]
        [string]$Release,

        [Parameter()]
        [switch]$Latest,

        [Parameter()]
        [switch]$Refresh,

        [Parameter()]
        [string]$Version,

        # Edition Filters (Implied naming convention handling)
        [Parameter(ParameterSetName = 'Default')]
        [switch]$Pro,
        [Parameter(ParameterSetName = 'Default')]
        [Alias('Home')]
        [switch]$HomeEdition,
        [Parameter(ParameterSetName = 'Default')]
        [switch]$Workstation,
        [Parameter(ParameterSetName = 'Default')]
        [switch]$Enterprise,
        [Parameter(ParameterSetName = 'Default')]
        [switch]$Education,
        [Parameter(ParameterSetName = 'Default')]
        [switch]$IoT,

        # Status Filter
        [Parameter()]
        [ValidateSet('All', 'Active', 'EOL', 'NearEOL')]
        [string]$Status = 'All'
    )

    begin {
        # Initialize Cache
        if (-not (Get-Command Get-WinEOLCache -ErrorAction SilentlyContinue)) {
            try { . $PSScriptRoot\..\Private\WinEOL.Cache.ps1 } catch {}
        }
    }

    process {
        # Input Validation (Security & Ruggedness)
        # Allow alphanumeric, hyphens, and wildcards.
        if ($ProductName -notmatch '^[a-zA-Z0-9\-\*\.]+$') {
            Throw "Invalid ProductName '$ProductName'. Product names must only contain letters, numbers, hyphens, periods, or wildcards (*). This check prevents malformed requests."
        }

        # Handle implied product name suffix (-W / -E)
        $suffixFilter = $null
        if ($Pro -or $HomeEdition -or $Workstation) { $suffixFilter = "*W" }
        if ($Enterprise -or $Education -or $IoT) { $suffixFilter = "*E" }

        # 1. Wildcard Handling
        if ($ProductName -match '\*') {
            Write-Verbose "Wildcard detected in '$ProductName'. Fetching all products to search."
            
            $cacheKey = "ALL_PRODUCTS"
            $allProducts = $null
            if (-not $Refresh) { $allProducts = (Get-WinEOLCache)[$cacheKey] }
            
            if ($null -eq $allProducts) {
                try {
                    $response = (Invoke-RestMethod "https://endoflife.date/api/v1/products" -ErrorAction Stop)
                    # Extract product names from v1 API response
                    $allProducts = $response.result | Select-Object -ExpandProperty name
                    Set-WinEOLCache -Key $cacheKey -Value $allProducts
                }
                catch {
                    Write-Error "Failed to fetch product list: $_"
                    return
                }
            }

            $foundProducts = $allProducts | Where-Object { $_ -like $ProductName }
            
            # Note: Suffix filter on *Product Names* works if products are named "foo-w". 
            # But for Windows 11, the suffix applies to *Releases*.
            # If the product list logic matches "windows-11", we recurse.
            # But "windows-11" isn't in product list.
            # So "windows-*" matches "windows", "windows-server".
            # Then we call Get-WinEOL "windows" ... filtering happens there?
            # Issue: "windows" contains *all* versions.
            # If user asks for "windows-*", they get "windows" product (all releases).
            # We might want to filter the *Output* of Get-WinEOL "windows" based on the Wildcard?
            # Complex. For now, basic wildcard matches Product Slugs.

            if (-not $foundProducts) {
                Write-Warning "No products found matching '$ProductName'."
                return
            }

            foreach ($m in $foundProducts) {
                Get-WinEOL -ProductName $m -Refresh:$Refresh -Status $Status -Latest:$Latest -Version $Version -Pro:$Pro -HomeEdition:$HomeEdition -Enterprise:$Enterprise -Education:$Education -IoT:$IoT -Workstation:$Workstation
            }
            return
        }

        # 2. Specific Product Handling
        $url = "https://endoflife.date/api/v1/products/$($ProductName)"
        if ($Release) { $url += "/releases/$Release" }
        elseif ($Latest) { $url += "/releases/latest" }

        $cacheKey = "PRODUCT_$ProductName"
        if ($Release) { $cacheKey += "_$Release" }
        if ($Latest) { $cacheKey += "_LATEST" }

        $data = $null
        if (-not $Refresh) { $data = (Get-WinEOLCache)[$cacheKey] }
        
        $fallbackMode = $false
        $fallbackFilter = $null
        $results = @()

        if ($null -eq $data) {
            try {
                $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
                $data = $response
                # Normalize API response (Handle 'result.releases' wrapper vs direct array)
                if ($data.result -and $data.result.releases) {
                    $data = $data.result.releases
                }

                if ($Latest) { $data = @($data) } 
                Set-WinEOLCache -Key $cacheKey -Value $data
            }
            catch {
                $err = $_
                if ($err.Exception.Response.StatusCode -eq 404) {
                    # Smart Fallback Logic
                    if ($ProductName -match '^windows-(\d+(\.\d+)?)$') {
                        Write-Verbose "Detected Windows version '$($matches[1])'. Redirecting to 'windows' product."
                        $fallbackProduct = 'windows'
                        $fallbackFilter = $matches[1] + "*"
                        $fallbackMode = $true
                    }
                    elseif ($ProductName -match '^windows-server-(.*)$') {
                        Write-Verbose "Detected Windows Server version '$($matches[1])'. Redirecting to 'windows-server' product."
                        $fallbackProduct = 'windows-server'
                        $fallbackFilter = "*" + $matches[1] + "*" 
                        # Note: Server versions are like "2019", "2012-r2". Regex capture needs match.
                        # windows-server-2019 -> match 1 = 2019. Filter *2019*.
                        $fallbackMode = $true
                    }
                     
                    if ($fallbackMode) {
                        # Recursive call with the base product, then we filter results
                        # BUT we can't easily recurse and filter inside. 
                        # We will fetch the base product data manually here.
                        try {
                            $url = "https://endoflife.date/api/v1/products/$fallbackProduct"
                            $data = Invoke-RestMethod -Uri $url -ErrorAction Stop
                            
                            # Normalize Fallback Data
                            if ($data.result -and $data.result.releases) {
                                $data = $data.result.releases
                            }

                            Set-WinEOLCache -Key "PRODUCT_$fallbackProduct" -Value $data
                        }
                        catch {
                            Write-Error "Failed to fetch fallback product '$fallbackProduct': $_"
                            return
                        }
                    }
                    else {
                        Write-Warning "Product '$ProductName' not found."
                        # Fuzzy (simplified)
                        return
                    }
                }
                else {
                    Write-Error "API Error: $($err.Message)"
                    return
                }
            }
        }


        foreach ($item in $data) {
            # Normalize Cycle/Name
            $cycle = if ($item.cycle) { $item.cycle } else { $item.name }
             
            # Apply Fallback Filter (e.g. only show "11" cycle for "windows-11" request)
            if ($fallbackMode) {
                if ($cycle -notlike $fallbackFilter -and $item.name -notlike $fallbackFilter) { continue }
            }
             
            # Apply Suffix Filter (Pro/Home/etc)
            if ($suffixFilter) {
                if ($item.name -notlike $suffixFilter) { continue }
            }

            # Apply Version Filter
            if ($Version) {
                $versionPattern = "*$Version*"
                if ($cycle -notlike $versionPattern) { continue }
            }

            # Calculate Days Remaining
            $eolDate = $null
            $days = 0
            $statusStr = "Active"
            $isSupported = $true
             
            # Handle both API formats: v1 API uses 'eolFrom', direct API uses 'eol'
            $eolValue = if ($item.eolFrom) { $item.eolFrom } else { $item.eol }
            
            # Check if already marked as EOL (v1 API)
            if ($item.PSObject.Properties['isEol'] -and $item.isEol -eq $true) {
                $statusStr = "EOL"
                $isSupported = $false
                if ($eolValue -as [DateTime]) {
                    $eolDate = [DateTime]$eolValue
                    $days = ($eolDate - (Get-Date)).Days
                }
            }
            elseif ($eolValue -and $eolValue -ne $true -and $eolValue -ne $false) {
                if ($eolValue -as [DateTime]) {
                    $eolDate = [DateTime]$eolValue
                    $days = ($eolDate - (Get-Date)).Days
                    
                    if ($days -lt 0) { 
                        $statusStr = "EOL" 
                        $isSupported = $false
                    }
                    elseif ($days -le 60) { $statusStr = "NearEOL" }
                }
            }
            elseif ($eolValue -eq $true) {
                # Boolean true usually means EOL in the past or simple "Yes"
                $statusStr = "EOL"
                $isSupported = $false
            }

            # Add Properties by creating new object with all properties
            $objProps = [ordered]@{}
            
            # Copy existing properties except ones we'll override
            $excludeProps = @('Cycle', 'EOL', 'DaysRemaining', 'Status', 'IsSupported', 'Product')
            foreach ($prop in $item.PSObject.Properties) {
                if ($prop.Name -notin $excludeProps) {
                    $objProps[$prop.Name] = $prop.Value
                }
            }
            
            # Add calculated properties
            $objProps['Cycle'] = $cycle
            $objProps['EOL'] = $eolDate
            $objProps['DaysRemaining'] = $days
            $objProps['Status'] = $statusStr
            $objProps['IsSupported'] = $isSupported
            $objProps['Product'] = $ProductName
            
            $obj = [PSCustomObject]$objProps
             
            # Add TypeName
            $obj.PSTypeNames.Insert(0, "WinEOL.ProductInfo")
             
            # Status Filter
            if ($Status -ne 'All' -and $statusStr -ne $Status) { continue }

            $results += $obj
        }
        
        return $results
    }
}
