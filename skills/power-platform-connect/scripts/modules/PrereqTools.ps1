# PrereqTools.ps1 — OS/arch detection, download + integrity verification, Ensure-DotNetSdk
# PowerShell 7+ (cross-platform)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Pinned baseline — update these in one place when upgrading
$script:DotNetSdkVersion = '10.0.203'

#region Platform detection

function Get-OsKind {
    <#
    .SYNOPSIS
        Returns one of: Windows, macOS, Debian, Ubuntu, RHEL, Alpine, Linux
    #>
    if ($IsWindows) { return 'Windows' }
    if ($IsMacOS)   { return 'macOS' }

    if (Test-Path '/etc/os-release') {
        $content = Get-Content '/etc/os-release' -Raw
        if ($content -match 'ID="?alpine"?')                   { return 'Alpine' }
        if ($content -match 'ID="?debian"?')                   { return 'Debian' }
        if ($content -match 'ID="?ubuntu"?|ID_LIKE.*ubuntu')   { return 'Ubuntu' }
        if ($content -match 'ID="?(rhel|centos|fedora|rocky|almalinux)"?') { return 'RHEL' }
    }
    return 'Linux'
}

function Get-ArchToken {
    <#
    .SYNOPSIS
        Returns one of: x64, arm64
    #>
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        'X64'   { return 'x64' }
        'Arm64' { return 'arm64' }
        default { return 'x64' }
    }
}

#endregion

#region Download and verification

function Invoke-VerifiedDownload {
    <#
    .SYNOPSIS
        Downloads a URL to a local path and verifies its SHA256 hash.
    #>
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$ExpectedSha256
    )
    Write-Log "Downloading: $Url"
    Invoke-WithRetry -OperationName "download $([IO.Path]::GetFileName($DestinationPath))" -Action {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing
    }
    Confirm-FileHash -FilePath $DestinationPath -ExpectedSha256 $ExpectedSha256
}

function Confirm-FileHash {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$ExpectedSha256
    )
    $actual = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    if ($actual.ToUpper() -ne $ExpectedSha256.ToUpper()) {
        Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
        Fail-Error 'hash-mismatch' "SHA256 mismatch for $FilePath. Expected: $ExpectedSha256  Got: $actual"
    }
    Write-Log "Hash verified: $([IO.Path]::GetFileName($FilePath))"
}

function Confirm-WindowsSignature {
    param([Parameter(Mandatory)][string]$FilePath)
    if (-not $IsWindows) { return }
    $sig = Get-AuthenticodeSignature -FilePath $FilePath
    if ($sig.Status -ne 'Valid') {
        Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
        Fail-Error 'signature-invalid' "Authenticode signature invalid for $FilePath. Status: $($sig.Status)"
    }
    Write-Log "Authenticode signature valid: $([IO.Path]::GetFileName($FilePath))"
}

#endregion

#region Ensure-DotNetSdk

function Test-DotNetSdkPresent {
    $cmd = Get-Command 'dotnet' -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    $raw = & dotnet --version 2>&1
    $ver = Parse-SemVer ($raw | Out-String)
    if (-not $ver) { return $false }
    # Accept any 10.x SDK
    return $ver.StartsWith('10.')
}

function Ensure-DotNetSdk {
    <#
    .SYNOPSIS
        Ensures .NET SDK 10.x is present. Installs it if missing.
    #>
    if (Test-DotNetSdkPresent) {
        $ver = Parse-SemVer (& dotnet --version 2>&1 | Out-String)
        Write-Log ".NET SDK already present: $ver"
        return
    }

    Write-Log ".NET SDK 10.x not found — installing…"
    $os = Get-OsKind

    switch ($os) {
        'Windows' { Install-DotNetSdkWindows }
        'macOS'   { Install-DotNetSdkMacOS   }
        'Debian'  { Install-DotNetSdkDebian   }
        'Ubuntu'  { Install-DotNetSdkUbuntu   }
        'RHEL'    { Install-DotNetSdkRhel     }
        'Alpine'  { Install-DotNetSdkFallback }
        default   { Install-DotNetSdkFallback }
    }

    Update-SessionPath

    if (-not (Test-DotNetSdkPresent)) {
        Fail-ActionRequired `
            -Code 'dotnet-missing' `
            -Remediation 'Install .NET SDK 10.0 manually, then re-run the bootstrap script.' `
            -NextCommand 'https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0' `
            -Detail "Automated install of .NET SDK $script:DotNetSdkVersion did not complete successfully."
    }
    $ver = Parse-SemVer (& dotnet --version 2>&1 | Out-String)
    Write-Log ".NET SDK installed: $ver"
}

#region Platform-specific .NET install

function Install-DotNetSdkWindows {
    $arch = Get-ArchToken
    # winget preferred; fallback to dotnet-install script
    $winget = Get-Command 'winget' -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Log 'Installing .NET SDK 10 via winget…'
        try {
            & winget install --id Microsoft.DotNet.SDK.10 --source winget --accept-package-agreements --accept-source-agreements --silent
            return
        } catch {
            Write-Log 'winget install failed; falling back to dotnet-install.ps1' -Level WARN
        }
    }
    # Fallback: official dotnet-install.ps1
    $tmp = Join-Path $env:TEMP 'dotnet-install.ps1'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile $tmp -UseBasicParsing
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tmp -Channel '10.0' -InstallDir (Join-Path $env:LOCALAPPDATA 'Microsoft' 'dotnet')
}

function Install-DotNetSdkMacOS {
    $brew = Get-Command 'brew' -ErrorAction SilentlyContinue
    if ($brew) {
        Write-Log 'Installing .NET SDK 10 via Homebrew…'
        & brew install --cask dotnet-sdk
        return
    }
    Install-DotNetSdkFallback
}

function Install-DotNetSdkDebian {
    Write-Log 'Installing .NET SDK 10 via Microsoft apt repo…'
    & sudo apt-get update -y
    & sudo apt-get install -y dotnet-sdk-10.0
}

function Install-DotNetSdkUbuntu {
    # Ubuntu may carry .NET in its own feeds; try that first
    Write-Log 'Installing .NET SDK 10 (Ubuntu)…'
    $result = & sudo apt-get install -y dotnet-sdk-10.0 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log 'Ubuntu native feed failed; trying dotnet-install.sh fallback' -Level WARN
        Install-DotNetSdkFallback
    }
}

function Install-DotNetSdkRhel {
    Write-Log 'Installing .NET SDK 10 via dnf…'
    & sudo dnf install -y dotnet-sdk-10.0
}

function Install-DotNetSdkFallback {
    Write-Log 'Installing .NET SDK 10 via dotnet-install.sh…'
    $tmp = '/tmp/dotnet-install.sh'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.sh' -OutFile $tmp -UseBasicParsing
    & bash $tmp --channel '10.0'
}

#endregion
#endregion
