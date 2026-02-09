$scriptPath = $PSScriptRoot
if (-not $scriptPath) {
    if ($MyInvocation.MyCommand.Path) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $scriptPath = Get-Location
    }
}
$moduleRoot = Join-Path $scriptPath "..\WinEOL"
$manifestPath = "c:\Code\GitHub\daileng\WinEOL\WinEOL\WinEOL.psd1"

# Debug
Write-Host "Script Path: $scriptPath"
Write-Host "Module Manifest: $manifestPath"

# Import globally
Get-Module WinEOL | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $manifestPath -Force

Describe "WinEOL Module Tests" {
    
    # InModuleScope is required to mock private functions or internal calls effectively
    InModuleScope WinEOL {
        Context "Get-WinEOL Parameters & Validation" {
            It "Should default ProductName to 'windows-*' if not specified" {
                # Mocking Invoke-RestMethod for v1 API
                Mock Invoke-RestMethod { 
                    # 1. Products endpoint returns v1 structure with result array
                    if ($Uri -match '/products$') { 
                        return [PSCustomObject]@{
                            result = @(
                                [PSCustomObject]@{ name = 'windows' },
                                [PSCustomObject]@{ name = 'windows-server' }
                            )
                        }
                    }
                    
                    # 2. Specific product endpoint returns v1 structure with releases
                    return [PSCustomObject]@{
                        result = [PSCustomObject]@{
                            releases = @(
                                [PSCustomObject]@{ 
                                    name    = '11-24h2-w'
                                    eolFrom = '2026-10-13'
                                    isEol   = $false
                                }
                            )
                        }
                    }
                }

                # Mock Cache to prevent using real cache
                Mock Get-WinEOLCache { return @{} }
                Mock Set-WinEOLCache { }
                
                # Mock Get-CimInstance to fail, forcing fallback to 'windows-*' default
                Mock Get-CimInstance { throw "Mock Error" }

                $result = Get-WinEOL
                $result | Should -Not -BeNullOrEmpty
                $result[0].Product | Should -BeIn @('windows', 'windows-server')
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

            It "Should bypass auto-detection when -ListAvailable is used" {
                # Setup Mocks
                Mock Invoke-RestMethod { 
                    if ($Uri -match '/products$') { 
                        return [PSCustomObject]@{
                            result = @([PSCustomObject]@{ name = 'windows' }) 
                        }
                    } 
                    return @()
                }
                Mock Get-WinEOLCache { return @{} }
                Mock Set-WinEOLCache { }
                
                # If auto-detection runs, this would be called. 
                # We can Mock it and Assert it was NOT called using Assert-MockCalled -Times 0
                Mock Get-CimInstance { return $null } 

                $res = Get-WinEOL -ListAvailable
                
                # Should have searched for windows-* (wildcard path)
                $res | Should -Not -BeNullOrEmpty
                
                # Verify Get-CimInstance was NOT called
                Assert-MockCalled Get-CimInstance -Times 0
            }
        }

        Context "Wrapper Functions" {
            It "Get-Win11EOL should call Get-WinEOL with 'windows-11'" {
                Mock Get-WinEOL { return "Called Base Function" } -ParameterFilter { $ProductName -eq 'windows-11' }
                
                $res = Get-Win11EOL
                $res | Should -Be "Called Base Function"
            }

            It "Get-Win11EOL should pass Version parameter to Get-WinEOL" {
                Mock Get-WinEOL { return "Called with Version" } -ParameterFilter { $ProductName -eq 'windows-11' -and $Version -eq '25H2' }
                
                $res = Get-Win11EOL -Version "25H2"
                $res | Should -Be "Called with Version"
            }

            It "Get-Win11ProEOL should call Get-Win11EOL with -Pro" {
                Mock Get-Win11EOL { return "Called Pro Wrapper" } -ParameterFilter { $Pro -eq $true }
                
                $res = Get-Win11ProEOL
                $res | Should -Be "Called Pro Wrapper"
            }

            It "Get-Win11ProEOL should pass Version parameter" {
                Mock Get-Win11EOL { return "Called Pro with Version" } -ParameterFilter { $Pro -eq $true -and $Version -eq '24H2' }
                
                $res = Get-Win11ProEOL -Version "24H2"
                $res | Should -Be "Called Pro with Version"
            }

            It "Get-WinServerEOL should call Get-WinEOL with 'windows-server-*'" {
                Mock Get-WinEOL { return "Called Base Function" } -ParameterFilter { $ProductName -eq 'windows-server-*' }
                
                $res = Get-WinServerEOL
                $res | Should -Be "Called Base Function"
            }
        }

        Context "Version Filtering" {
            It "Should filter results by Version parameter" {
                Mock Invoke-RestMethod { 
                    return @(
                        [PSCustomObject]@{ name = '11-25h2-e'; cycle = '11-25h2-e'; eol = '2028-10-10' },
                        [PSCustomObject]@{ name = '11-24h2-e'; cycle = '11-24h2-e'; eol = '2027-10-12' }
                    ) 
                }
                Mock Get-WinEOLCache { return @{} }
                Mock Set-WinEOLCache { }

                $res = Get-WinEOL -ProductName "windows-11" -Version "25H2"
                $res.Count | Should -Be 1
                $res[0].Cycle | Should -BeLike "*25h2*"
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
# End of file
