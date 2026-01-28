function Get-WinEOLCache {
    if ($null -eq $script:WinEOLCache) {
        $script:WinEOLCache = @{}
    }
    return $script:WinEOLCache
}

function Set-WinEOLCache {
    param($Key, $Value)
    if ($null -eq $script:WinEOLCache) {
        $script:WinEOLCache = @{}
    }
    $script:WinEOLCache[$Key] = $Value
}

function Clear-WinEOLCache {
    $script:WinEOLCache = @{}
    Write-Verbose "WinEOL Cache Cleared."
}
