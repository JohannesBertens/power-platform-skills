# PacTools.ps1 — pac discovery, install/update, latest-version lookup
# PowerShell 7+ (cross-platform)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:PacPackageId = 'Microsoft.PowerApps.CLI.Tool'
$script:NuGetFeedUrl = "https://api.nuget.org/v3-flatcontainer/$($script:PacPackageId.ToLower())/index.json"

#region Discovery

function Find-PacCommand {
    <#
    .SYNOPSIS
        Returns the resolved path to pac, or $null if not found.
    #>
    $cmd = Get-Command 'pac' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Get-InstalledPacVersion {
    <#
    .SYNOPSIS
        Returns the installed pac version string, or empty string on failure.
    #>
    # Primary: parse from pac banner output
    try {
        $raw = & pac 2>&1 | Out-String
        $ver = Parse-SemVer $raw
        if ($ver) { return $ver }
    } catch { }

    # Fallback: dotnet tool list --global
    try {
        $raw = & dotnet tool list --global 2>&1 | Out-String
        if ($raw -match [regex]::Escape($script:PacPackageId) + '\s+(\S+)') {
            $ver = Parse-SemVer $Matches[1]
            if ($ver) { return $ver }
        }
    } catch { }

    return ''
}

#endregion

#region Latest-version lookup

function Get-LatestPacVersion {
    <#
    .SYNOPSIS
        Returns the latest pac version from NuGet JSON, or empty string on network/parse failure.
    #>
    # Primary: NuGet machine-readable JSON
    try {
        $response = Invoke-WithRetry -MaxAttempts 2 -OperationName 'NuGet version lookup' -Action {
            $ProgressPreference = 'SilentlyContinue'
            (Invoke-WebRequest -Uri $script:NuGetFeedUrl -UseBasicParsing).Content | ConvertFrom-Json
        }
        $versions = $response.versions
        if ($versions -and $versions.Count -gt 0) {
            # Filter stable versions (no pre-release suffix).
            # pac uses 3-part versions (e.g. 1.2.3); this pattern intentionally excludes
            # pre-release suffixes (-beta, -preview) and build metadata (+g…).
            $stable = $versions | Where-Object { $_ -match '^\d+\.\d+\.\d+$' }
            if ($stable) {
                $latest = $stable[-1]
                return $latest
            }
            return $versions[-1]
        }
    } catch {
        Write-Log "NuGet JSON lookup failed: $_" -Level WARN
    }

    # Fallback: dotnet tool search
    try {
        $raw = & dotnet tool search $script:PacPackageId --take 1 2>&1 | Out-String
        if ($raw -imatch [regex]::Escape($script:PacPackageId) + '\s+(\S+)') {
            $ver = Parse-SemVer $Matches[1]
            if ($ver) { return $ver }
        }
    } catch {
        Write-Log "dotnet tool search fallback failed: $_" -Level WARN
    }

    return ''
}

#endregion

#region Install and update

function Install-Pac {
    Write-Log "Installing $script:PacPackageId…"
    try {
        Invoke-WithRetry -OperationName 'pac install' -Action {
            & dotnet tool install --global $script:PacPackageId
        }
    } catch {
        Fail-Error 'pac-install-failed' "dotnet tool install --global $script:PacPackageId failed: $_"
    }
    Update-SessionPath
}

function Update-Pac {
    Write-Log "Updating $script:PacPackageId…"
    try {
        Invoke-WithRetry -OperationName 'pac update' -Action {
            & dotnet tool update --global $script:PacPackageId
        }
    } catch {
        Fail-Error 'pac-update-failed' "dotnet tool update --global $script:PacPackageId failed: $_"
    }
    Update-SessionPath
}

function Ensure-PacInstalled {
    <#
    .SYNOPSIS
        Installs pac if missing; upgrades if outdated. Emits final STATUS marker.
    #>
    $pacPath = Find-PacCommand
    if (-not $pacPath) {
        Write-Log 'pac not found — installing…'
        Install-Pac
        $pacPath = Find-PacCommand
        if (-not $pacPath) {
            Fail-Error 'pac-install-failed' 'pac was not found on PATH after install attempt.'
        }
        Write-Log "pac installed at: $pacPath"
    }

    $installed = Get-InstalledPacVersion
    if (-not $installed) {
        Write-Status 'ERROR (pac-version-unknown)'
        Write-Detail 'pac is present but its version could not be determined. Try reinstalling.'
        exit 1
    }
    Write-Log "Installed pac version: $installed"

    $latest = Get-LatestPacVersion
    if (-not $latest) {
        Write-Log 'Could not determine latest pac version from NuGet.' -Level WARN
        Write-Status 'DEGRADED (latest-version-unavailable)'
        Write-Detail "Installed: $installed. Latest version lookup failed; pac may or may not be current."
        exit 0
    }

    Write-Log "Latest pac version:    $latest"

    $cmp = Compare-SemVer $installed $latest
    if ($cmp -lt 0) {
        Write-Log "pac is outdated ($installed < $latest) — upgrading…"
        Update-Pac
        $installed = Get-InstalledPacVersion
        Write-Log "pac updated to: $installed"
    }

    Write-Status 'OK'
    Write-Detail "pac $installed is installed and up to date."
}

#endregion
