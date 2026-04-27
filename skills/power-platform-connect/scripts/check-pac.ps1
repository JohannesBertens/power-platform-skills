# check-pac.ps1 — PowerShell 7 entrypoint: ensure dotnet, ensure/update pac
# PowerShell 7+ (cross-platform)
#
# Usage:
#   pwsh -File check-pac.ps1              # validate/repair pac only
#   pwsh -File check-pac.ps1 -Bootstrap   # also install missing .NET SDK

param(
    [switch]$Bootstrap
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleDir = Join-Path $PSScriptRoot 'modules'

# Load helper modules
. (Join-Path $moduleDir 'Common.ps1')
. (Join-Path $moduleDir 'PrereqTools.ps1')
. (Join-Path $moduleDir 'PacTools.ps1')

#region dotnet prerequisite

$dotnetPresent = Test-DotNetSdkPresent

if (-not $dotnetPresent) {
    if ($Bootstrap) {
        Write-Log 'Bootstrap mode: attempting to install .NET SDK 10…'
        Ensure-DotNetSdk
        $dotnetPresent = Test-DotNetSdkPresent
    }

    if (-not $dotnetPresent) {
        $os = Get-OsKind
        $installHint = switch ($os) {
            'Windows' { 'winget install Microsoft.DotNet.SDK.10' }
            'macOS'   { 'brew install --cask dotnet-sdk' }
            'Debian'  { 'sudo apt-get install -y dotnet-sdk-10.0' }
            'Ubuntu'  { 'sudo apt-get install -y dotnet-sdk-10.0' }
            'RHEL'    { 'sudo dnf install -y dotnet-sdk-10.0' }
            default   { 'bash <(curl -sL https://dot.net/v1/dotnet-install.sh) --channel 10.0' }
        }
        Fail-ActionRequired `
            -Code 'dotnet-missing' `
            -Remediation 'Install .NET SDK 10.0 for your platform, then re-run this script.' `
            -NextCommand $installHint `
            -Detail 'pac is a .NET global tool and requires the .NET SDK to install and run.'
    }
}

$dotnetVer = Parse-SemVer (& dotnet --version 2>&1 | Out-String)
Write-Log ".NET SDK: $dotnetVer"

#endregion

#region pac install/update/verify

Ensure-PacInstalled

#endregion
