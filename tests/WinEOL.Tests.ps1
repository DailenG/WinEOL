$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Parent $here) + "\WinEOL"
Import-Module $sut -Force

InModuleScope WinEOL {
    Describe "WinEOL Module Tests" {
        
        Context "Get-WinEOL Parameters & Validation" {
            It "Should default ProductName to 'windows-*' if not specified" {
                # Mocking Invoke-RestMethod. 
                # 1. 'products' endpoint returns list of slugs (strings)
                # 2. 'products/windows-11' endpoint returns details
                Mock Invoke-RestMethod { 
                    # Pester binds parameters. Use $Uri.
                    if ($Uri -match '/products$') { return @('windows-11') }
                    
                    # Fallback for specific product details
                    return @(
                        [PSCustomObject]@{ 
                            name  = 'windows-11'
                            cycle = '23H2'
                            eol   = '2025-01-01' 
                        }
                    )
                }

                # Mock Cache to prevent using real cache
                Mock Get-WinEOLCache { return @{} }
                Mock Set-WinEOLCache { }

                $result = Get-WinEOL
                $result | Should -Not -BeNullOrEmpty
                $result[0].Product | Should -Be "windows-11"
            }

            It "Should throw error for invalid characters in ProductName" {
                { Get-WinEOL -ProductName "windows;DROP TABLE" } | Should -Throw
                { Get-WinEOL -ProductName "http://evil.com" } | Should -Throw
            }

            It "Should allow valid characters (letters, numbers, hyphens, wildcards)" {
                Mock Invoke-RestMethod { return @() }
                Mock Get-WinEOLCache { return @{} }
                Mock Set-WinEOLCache { }

                { Get-WinEOL -ProductName "windows-11" } | Should -Not -Throw
                { Get-WinEOL -ProductName "windows-10.1" } | Should -Not -Throw
                { Get-WinEOL -ProductName "*" } | Should -Not -Throw
            }
        }

        Context "Wrapper Functions" {
            It "Get-Win11EOL should call Get-WinEOL with 'windows-11'" {
                Mock Get-WinEOL { return "Called Base Function" } -ParameterFilter { $ProductName -eq 'windows-11' }
                
                $res = Get-Win11EOL
                $res | Should -Be "Called Base Function"
            }

            It "Get-WinServerEOL should call Get-WinEOL with 'windows-server-*'" {
                Mock Get-WinEOL { return "Called Base Function" } -ParameterFilter { $ProductName -eq 'windows-server-*' }
                
                $res = Get-WinServerEOL
                $res | Should -Be "Called Base Function"
            }
        }

        Context "Output Object Structure" {
            It "Should return WinEOL.ProductInfo objects with correct properties" {
                Mock Invoke-RestMethod { 
                    return @(
                        [PSCustomObject]@{ 
                            name        = 'windows-11'
                            cycle       = '23H2'
                            eol         = (Get-Date).AddDays(10).ToString("yyyy-MM-dd")
                            releaseDate = '2020-01-01'
                            isLts       = $false
                        }
                    ) 
                }
                Mock Get-WinEOLCache { return @{} }
                Mock Set-WinEOLCache { }

                $res = Get-WinEOL -ProductName "windows-11"
                $p = $res[0]

                $p.PSTypeNames[0] | Should -Be "WinEOL.ProductInfo"
                $p.Status | Should -Be "NearEOL" # < 60 days
                $p.DaysRemaining | Should -BeLessThan 60
                $p.IsSupported | Should -Be $true
            }
        }
    }
}
