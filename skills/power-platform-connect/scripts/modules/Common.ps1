# Common.ps1 — shared logging, status markers, retry, version helpers
# PowerShell 7+ (cross-platform)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Logging

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
    )
    $ts = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$ts][$Level] $Message"
}

#endregion

#region Status markers

function Write-Status {
    param([Parameter(Mandatory)][string]$Code)
    Write-Host "STATUS: $Code"
}

function Write-Remediation {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "REMEDIATION: $Message"
}

function Write-NextCommand {
    param([Parameter(Mandatory)][string]$Command)
    Write-Host "NEXT_COMMAND: $Command"
}

function Write-Detail {
    param([Parameter(Mandatory)][string]$Detail)
    Write-Host "DETAIL: $Detail"
}

function Fail-ActionRequired {
    param(
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Remediation,
        [Parameter(Mandatory)][string]$NextCommand,
        [string]$Detail = ''
    )
    Write-Status "ACTION_REQUIRED ($Code)"
    Write-Remediation $Remediation
    Write-NextCommand $NextCommand
    if ($Detail) { Write-Detail $Detail }
    exit 1
}

function Fail-Error {
    param(
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Detail
    )
    Write-Status "ERROR ($Code)"
    Write-Detail $Detail
    exit 1
}

#endregion

#region Version helpers

function Compare-SemVer {
    <#
    .SYNOPSIS
        Returns -1, 0, or 1 (a < b, a == b, a > b). Ignores build metadata after '+'.
    #>
    param(
        [Parameter(Mandatory)][string]$A,
        [Parameter(Mandatory)][string]$B
    )
    $clean = { param($v) ($v -split '\+')[0] -split '-' | Select-Object -First 1 }
    try {
        $va = [version](& $clean $A)
        $vb = [version](& $clean $B)
        return $va.CompareTo($vb)
    } catch {
        # Fall back to string comparison if parsing fails
        if ($A -lt $B) { return -1 }
        if ($A -gt $B) { return  1 }
        return 0
    }
}

function Parse-SemVer {
    <#
    .SYNOPSIS
        Extracts the first semver-like token from a string. Returns empty string on failure.
    #>
    param([string]$Text)
    if ($Text -match '(\d+\.\d+\.\d+(?:\.\d+)?)') {
        return $Matches[1]
    }
    return ''
}

#endregion

#region Retry

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [int]$MaxAttempts = 3,
        [int]$InitialDelaySeconds = 2,
        [string]$OperationName = 'operation'
    )
    $delay = $InitialDelaySeconds
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return (& $Action)
        } catch {
            if ($attempt -eq $MaxAttempts) { throw }
            Write-Log "Attempt $attempt/$MaxAttempts for '$OperationName' failed: $_. Retrying in ${delay}s…" -Level WARN
            Start-Sleep -Seconds $delay
            $delay *= 2
        }
    }
}

#endregion

#region PATH refresh

function Update-SessionPath {
    <#
    .SYNOPSIS
        Refreshes $env:PATH from the machine and user PATH registry keys on Windows,
        or re-reads common tool directories on Unix.
    #>
    if ($IsWindows) {
        $machinePath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
        $userPath    = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        $env:PATH    = ($machinePath, $userPath | Where-Object { $_ }) -join [IO.Path]::PathSeparator
    } else {
        # Prepend common dotnet tool paths that may have just been created
        $dotnetTools = Join-Path $HOME '.dotnet' 'tools'
        if (Test-Path $dotnetTools) {
            if ($env:PATH -notlike "*$dotnetTools*") {
                $env:PATH = "${dotnetTools}$([IO.Path]::PathSeparator)$env:PATH"
            }
        }
    }
}

#endregion
