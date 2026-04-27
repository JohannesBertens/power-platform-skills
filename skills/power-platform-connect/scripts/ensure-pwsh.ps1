# ensure-pwsh.ps1 — Windows PowerShell 5.1-compatible bootstrapper
# Ensures PowerShell 7 is present (MSI primary, winget fallback), then delegates.
#
# Pinned baseline (update here when upgrading):
$PwshVersion = '7.6.1'
$PwshMsiSha256 = @{
    # SHA256 hashes for PowerShell $PwshVersion MSI installers.
    # Update these when upgrading $PwshVersion.
    # Obtain from: https://github.com/PowerShell/PowerShell/releases/tag/v<version>
    # and verify against the .sha256 files published alongside each MSI release asset.
    'x64'  = 'A8BFB25D78A49A10A81E01EF00DF0CCAB68F7BBDCE16ABF1A1B41ADCC4DEE10F'
    'arm64'= 'D14B8EB42DA0E1B8082DD14F89EF9A46B9B36B9DDDEE6F4EACD74FACBC07A2EF'
}

$ErrorActionPreference = 'Stop'

function Get-ArchToken {
    $arch = [System.Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE')
    if ($arch -eq 'ARM64') { return 'arm64' }
    return 'x64'
}

function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH = ($machine, $user | Where-Object { $_ }) -join ';'
}

function Test-PwshPresent {
    $null -ne (Get-Command 'pwsh.exe' -ErrorAction SilentlyContinue)
}

function Install-PwshViaMsi {
    $arch       = Get-ArchToken
    $msiName    = "PowerShell-${PwshVersion}-win-${arch}.msi"
    $msiUrl     = "https://github.com/PowerShell/PowerShell/releases/download/v${PwshVersion}/${msiName}"
    $msiPath    = Join-Path $env:TEMP $msiName
    $expectedHash = $PwshMsiSha256[$arch]

    Write-Host "[INFO] Downloading PowerShell MSI: $msiUrl"
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
    } catch {
        Write-Host "[WARN] MSI download failed: $_"
        return $false
    }

    # Verify SHA256
    $actual = (Get-FileHash -Path $msiPath -Algorithm SHA256).Hash
    if ($actual.ToUpper() -ne $expectedHash.ToUpper()) {
        Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
        Write-Host "STATUS: ERROR (hash-mismatch)"
        Write-Host "DETAIL: Expected $expectedHash, got $actual for $msiName"
        exit 1
    }
    Write-Host "[INFO] SHA256 verified."

    # Verify Authenticode
    $sig = Get-AuthenticodeSignature -FilePath $msiPath
    if ($sig.Status -ne 'Valid') {
        Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
        Write-Host "STATUS: ERROR (signature-invalid)"
        Write-Host "DETAIL: Authenticode status: $($sig.Status)"
        exit 1
    }
    Write-Host "[INFO] Authenticode signature valid."

    Write-Host "[INFO] Installing PowerShell $PwshVersion MSI silently…"
    $result = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart ADD_PATH=1" -Wait -PassThru
    Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

    if ($result.ExitCode -notin @(0, 3010)) {
        Write-Host "[WARN] msiexec exited with code $($result.ExitCode)"
        return $false
    }
    return $true
}

function Install-PwshViaWinget {
    $winget = Get-Command 'winget.exe' -ErrorAction SilentlyContinue
    if (-not $winget) { return $false }
    Write-Host "[INFO] Trying winget fallback for PowerShell install…"
    try {
        & winget.exe install --id Microsoft.PowerShell --source winget --installer-type wix `
            --accept-package-agreements --accept-source-agreements --silent
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Host "[WARN] winget install failed: $_"
        return $false
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if (Test-PwshPresent) {
    $ver = & pwsh.exe --version 2>$null
    Write-Host "[INFO] pwsh already present: $ver"
} else {
    Write-Host "[INFO] pwsh not found — installing PowerShell $PwshVersion…"

    $installed = Install-PwshViaMsi
    if (-not $installed) {
        $installed = Install-PwshViaWinget
    }

    Update-SessionPath

    if (-not (Test-PwshPresent)) {
        Write-Host "STATUS: ACTION_REQUIRED (pwsh-missing)"
        Write-Host "REMEDIATION: Install PowerShell 7 manually, then re-run ensure-pwsh.cmd."
        Write-Host "NEXT_COMMAND: winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements"
        exit 1
    }
    Write-Host "[INFO] PowerShell 7 installed successfully."
}

Update-SessionPath

# Delegate to PowerShell 7
$checkPacScript = Join-Path $PSScriptRoot 'check-pac.ps1'
& pwsh.exe -File $checkPacScript -Bootstrap @args
exit $LASTEXITCODE
