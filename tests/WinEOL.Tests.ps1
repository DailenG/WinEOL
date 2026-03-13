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
$manifestPath = (Join-Path $moduleRoot "WinEOL.psd1")

# Debug
Write-Host "Script Path: $scriptPath"
Write-Host "Module Manifest: $manifestPath"

# Pester 5: ensure ONLY our local copy is loaded — remove any installed/cached copies first.
# Strip any PSModulePath entries pointing to an installed WinEOL to prevent
# the "Multiple script or manifest modules" Pester error when using -ModuleName.
$cleanedPaths = $env:PSModulePath -split [IO.Path]::PathSeparator | Where-Object {
    -not (Test-Path (Join-Path $_ 'WinEOL'))
}
$env:PSModulePath = $cleanedPaths -join [IO.Path]::PathSeparator

Get-Module WinEOL | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $manifestPath -Force

Describe "WinEOL Module Tests" {

    # -------------------------------------------------------------------------
    # IMPORTANT: Without InModuleScope, ALL mocks of module-internal cmdlets
    # (like Invoke-RestMethod called from within the module) must use
    # -ModuleName WinEOL so Pester redirects them in the module's scope.
    # -------------------------------------------------------------------------

    Context "Get-WinEOL Parameters & Validation" {

        It "Should default ProductName to 'windows-*' if not specified" {
            # Mock products endpoint
            Mock -ModuleName WinEOL Invoke-RestMethod {
                if ($Uri -match '/products$') {
                    return [PSCustomObject]@{
                        result = @(
                            [PSCustomObject]@{ name = 'windows' },
                            [PSCustomObject]@{ name = 'windows-server' }
                        )
                    }
                }
                # Specific product call — return release data
                return [PSCustomObject]@{
                    result = [PSCustomObject]@{
                        releases = @(
                            [PSCustomObject]@{
                                name    = '11-24h2-w'
                                cycle   = '11-24h2-w'
                                eolFrom = '2026-10-13'
                                isEol   = $false
                            }
                        )
                    }
                }
            }
            Mock -ModuleName WinEOL Get-CimInstance { throw "Mock Error" }

            $result = Get-WinEOL
            $result | Should -Not -BeNullOrEmpty
            $result[0].Product -in @('windows', 'windows-server') | Should -Be $true
        }

        It "Should throw error for invalid characters in ProductName" {
            { Get-WinEOL -ProductName "windows;DROP TABLE" } | Should -Throw
            { Get-WinEOL -ProductName "http://evil.com" }   | Should -Throw
        }

        It "Should allow valid characters (letters, numbers, hyphens, wildcards)" {
            # For wildcard paths: products endpoint must return well-formed result.
            # For specific product paths: releases structure is expected with at least one item.
            # NOTE: empty @() is falsy in PowerShell; result.releases condition fails -> $data not reassigned.
            Mock -ModuleName WinEOL Invoke-RestMethod {
                if ($Uri -match '/products$') {
                    return [PSCustomObject]@{
                        result = @(
                            [PSCustomObject]@{ name = 'windows-11' },
                            [PSCustomObject]@{ name = 'windows-10.1' }
                        )
                    }
                }
                return [PSCustomObject]@{
                    result = [PSCustomObject]@{
                        releases = @(
                            [PSCustomObject]@{ cycle = 'dummy'; eol = '2099-01-01'; releaseDate = '2020-01-01' }
                        )
                    }
                }
            }

            { Get-WinEOL -ProductName "windows-11"   } | Should -Not -Throw
            { Get-WinEOL -ProductName "windows-10.1" } | Should -Not -Throw
            { Get-WinEOL -ProductName "*"             } | Should -Not -Throw
        }

        It "Should bypass auto-detection when -ListAvailable is used" {
            Mock -ModuleName WinEOL Invoke-RestMethod {
                if ($Uri -match '/products') {
                    return [PSCustomObject]@{
                        result = @([PSCustomObject]@{ name = 'windows-11' })
                    }
                }
                return [PSCustomObject]@{
                    result = [PSCustomObject]@{
                        releases = @(
                            [PSCustomObject]@{
                                cycle       = '21H2'
                                name        = '21H2'
                                eol         = '2099-01-01'
                                releaseDate = '2021-01-01'
                            }
                        )
                    }
                }
            }
            Mock -ModuleName WinEOL Get-CimInstance { return $null }

            $res = Get-WinEOL -ListAvailable
            $res | Should -Not -BeNullOrEmpty

            # Auto-detection path should NOT have been triggered
            Assert-MockCalled -ModuleName WinEOL Get-CimInstance -Times 0
        }
    }

    Context "Wrapper Functions" {

        It "Get-Win11EOL should call Get-WinEOL with 'windows-11'" {
            Mock -ModuleName WinEOL Get-WinEOL { return "Called Base Function" } `
                -ParameterFilter { $ProductName -eq 'windows-11' }

            $res = Get-Win11EOL
            $res | Should -Be "Called Base Function"
        }

        It "Get-Win11EOL should pass Version parameter to Get-WinEOL" {
            Mock -ModuleName WinEOL Get-WinEOL { return "Called with Version" } `
                -ParameterFilter { $ProductName -eq 'windows-11' -and $Version -eq '25H2' }

            $res = Get-Win11EOL -Version "25H2"
            $res | Should -Be "Called with Version"
        }

        It "Get-Win11ProEOL should call Get-Win11EOL with -Pro" {
            Mock -ModuleName WinEOL Get-Win11EOL { return "Called Pro Wrapper" } `
                -ParameterFilter { $Pro -eq $true }

            $res = Get-Win11ProEOL
            $res | Should -Be "Called Pro Wrapper"
        }

        It "Get-Win11ProEOL should pass Version parameter" {
            Mock -ModuleName WinEOL Get-Win11EOL { return "Called Pro with Version" } `
                -ParameterFilter { $Pro -eq $true -and $Version -eq '24H2' }

            $res = Get-Win11ProEOL -Version "24H2"
            $res | Should -Be "Called Pro with Version"
        }

        It "Get-WinServerEOL should call Get-WinEOL with 'windows-server-*'" {
            Mock -ModuleName WinEOL Get-WinEOL { return "Called Base Function" } `
                -ParameterFilter { $ProductName -eq 'windows-server-*' }

            $res = Get-WinServerEOL
            $res | Should -Be "Called Base Function"
        }
    }

    Context "Version Filtering" {

        It "Should filter results by Version parameter" {
            Mock -ModuleName WinEOL Invoke-RestMethod {
                return [PSCustomObject]@{
                    result = [PSCustomObject]@{
                        releases = @(
                            [PSCustomObject]@{ cycle = '11-25h2-e'; name = '11-25h2-e'; eol = '2028-10-10'; releaseDate = '2021-01-01' },
                            [PSCustomObject]@{ cycle = '11-24h2-e'; name = '11-24h2-e'; eol = '2027-10-12'; releaseDate = '2020-10-01' }
                        )
                    }
                }
            }

            $res = Get-WinEOL -ProductName "windows-11" -Version "25H2"
            # Use @() wrapper for PS5.1 compatibility: a single PSCustomObject has .Count = $null in PS5
            @($res).Count | Should -Be 1
            $res[0].Cycle -like "*25h2*" | Should -Be $true
        }
    }

    Context "Output Object Structure" {

        It "Should return WinEOL.ProductInfo objects with correct properties" {
            # EOL 10 days from now => NearEOL (< 60 days)
            $nearDate = (Get-Date).AddDays(10).ToString("yyyy-MM-dd")

            Mock -ModuleName WinEOL Invoke-RestMethod {
                return [PSCustomObject]@{
                    result = [PSCustomObject]@{
                        releases = @(
                            [PSCustomObject]@{
                                name        = 'windows-11'
                                cycle       = '23H2'
                                eol         = $nearDate
                                releaseDate = '2020-01-01'
                                isLts       = $false
                            }
                        )
                    }
                }
            }

            $res = Get-WinEOL -ProductName "windows-11"
            $p = $res[0]

            $p.PSTypeNames[0]        | Should -Be "WinEOL.ProductInfo"
            $p.Status                | Should -Be "NearEOL"   # < 60 days
            $p.DaysRemaining -lt 60  | Should -Be $true
            $p.IsSupported           | Should -Be $true
        }
    }
}
# End of file
