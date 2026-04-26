# Plan: PowerShell Migration + Full Bootstrapping

**Date:** 2026-04-26
**Version:** v1.1.0
**Status:** Approved

## Summary

Rewrite all `.sh` scripts to PowerShell 7 (cross-platform). Add platform-specific bootstrappers that install PowerShell and .NET SDK if missing. The `pac` CLI is silently auto-installed or auto-upgraded.

## Decisions

| Decision | Choice |
|---|---|
| Auto-install behavior | Silent auto-install (no prompts) |
| Keep .sh files? | No — remove entirely (clean break) |
| Windows bootstrapper | CMD batch file (`.cmd`) |
| Bootstrap dotnet too? | Yes — .NET SDK is required for `dotnet tool` commands |

## Current State

- **1 shell script**: `skills/power-platform-connect/scripts/check-pac.sh`
  - Checks if `pac` CLI is installed
  - Reports version status (installed vs latest)
  - Does NOT install or upgrade
- **No PowerShell scripts** exist
- SKILL.md references the `.sh` script directly
- Prerequisites in `docs/setup.md` list "Bash 3+"

## Target State

- All logic in PowerShell 7 (cross-platform: Windows, macOS, Linux)
- Platform bootstrappers ensure PowerShell 7 and .NET SDK are installed
- `pac` is silently auto-installed if missing, auto-upgraded if outdated
- No `.sh` files remain

## File Structure

```
skills/power-platform-connect/scripts/
├── ensure-pwsh.sh              # Bash: Linux/macOS/WSL bootstrap (pwsh + dotnet)
├── ensure-pwsh.cmd             # CMD: Windows bootstrap (pwsh + dotnet)
├── check-pac.ps1               # PowerShell 7: verify/install/upgrade pac
└── (check-pac.sh DELETED)
```

## Implementation Steps

### Step 1 — Create `scripts/ensure-pwsh.sh`

Bash script for **Linux / macOS / WSL**. Solves the chicken-and-egg problem (can't run PowerShell to install PowerShell).

**Logic:**

1. Check if `pwsh` is on PATH → if yes, skip to step 4
2. Detect OS and install PowerShell 7:
   - **macOS**: check for Homebrew → `brew install powershell/tap/powershell` (fallback: download `.pkg` from GitHub releases)
   - **Debian/Ubuntu**: add Microsoft package repo → `sudo apt-get install -y powershell`
   - **RHEL/Fedora**: add Microsoft repo → `sudo dnf install -y powershell`
   - **Alpine**: add community repo → `sudo apk add powershell`
   - **Other Linux**: download `tar.gz` from GitHub releases, extract to `/usr/local/microsoft/powershell/7`, symlink to `/usr/local/bin/pwsh`
3. Verify `pwsh` is now available
4. Check if `dotnet` is on PATH → if not, install .NET SDK 8.0:
   - **macOS**: `brew install dotnet-sdk`
   - **Linux**: use Microsoft package repos or the official `dotnet-install.sh` script from `https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh`
5. Delegate: `pwsh -File "<script_dir>/check-pac.ps1" "$@"`

### Step 2 — Create `scripts/ensure-pwsh.cmd`

CMD batch file for **native Windows** (no PowerShell 7 pre-installed, but Windows PowerShell 5.1 is always available).

**Logic:**

1. Check if `pwsh.exe` is on PATH → if yes, skip to step 4
2. Install PowerShell 7:
   - Prefer `winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements`
   - Fallback: use `powershell -Command "Invoke-WebRequest"` to download MSI from GitHub releases, then `msiexec /quiet ADD_PATH=1`
3. Refresh PATH in current session
4. Check if `dotnet` is on PATH → if not:
   - `winget install Microsoft.DotNet.SDK.8 --accept-package-agreements --accept-source-agreements`
   - Fallback: download and run dotnet-install script via `powershell -Command`
5. Delegate: `pwsh -File "<script_dir>\check-pac.ps1" %*`

### Step 3 — Create `scripts/check-pac.ps1`

PowerShell 7 script — **cross-platform** (Windows / macOS / Linux).

**Logic:**

1. Check `dotnet` SDK is available → if not, error with instructions to run bootstrapper
2. Check `pac` is on PATH:
   - If not found → `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`
   - Refresh PATH after install
3. Get installed version:
   - Parse `pac 2>&1` output for semver pattern
   - Fallback: parse `dotnet tool list --global` output
   - If undetermined → exit 1
4. Get latest version from NuGet:
   - Parse `dotnet tool search Microsoft.PowerApps.CLI.Tool --take 1` output
   - If unreachable → warn and exit 0 (non-fatal)
5. Compare versions:
   - If outdated → `dotnet tool update --global Microsoft.PowerApps.CLI.Tool` (silent)
   - Verify new version after upgrade
6. Report final status

**Bash → PowerShell translation reference:**

| Bash | PowerShell 7 |
|---|---|
| `command -v pac` | `Get-Command pac -ErrorAction SilentlyContinue` |
| `grep -oP '\d+\.\d+\.\d+'` | `-match '(\d+\.\d+\.\d+)'` + `$Matches[1]` |
| `awk '{print $2}'` | `-match` with capture group or `.Split()` |
| `head -1` | `Select-Object -First 1` |
| `set -euo pipefail` | `$ErrorActionPreference = 'Stop'` |

**Exit codes** (same semantics as the bash version):

| Code | Meaning |
|------|---------|
| 0 | Success (installed/upgraded/up-to-date/warning-only) |
| 1 | Fatal error (dotnet missing, pac install failed, version undetermined) |

### Step 4 — Update `SKILL.md`

- Change `bash skills/power-platform-connect/scripts/check-pac.sh` → `pwsh skills/power-platform-connect/scripts/check-pac.ps1`
- Add bootstrapper commands for when `pwsh` is not available
- Update the three-case flow: not installed → auto-install; outdated → auto-upgrade; up to date → confirm
- Document the bootstrappers also handle .NET SDK installation

### Step 5 — Delete `check-pac.sh`

Remove:
- `skills/power-platform-connect/scripts/check-pac.sh`
- `.pi/skills/power-platform-connect/scripts/check-pac.sh`

### Step 6 — Update Documentation

| File | Changes |
|---|---|
| `docs/setup.md` | Replace "Bash 3+" prerequisite with "PowerShell 7+ (auto-installed by bootstrappers)"; update directory tree to show new files; update prerequisites table |
| `docs/skills.md` | Update script listing from `check-pac.sh` to `check-pac.ps1` + `ensure-pwsh.sh` + `ensure-pwsh.cmd`; add note about auto-install behavior |
| `README.md` | Update any references to bash/check-pac.sh |
| `CHANGELOG.md` | Add v1.1.0 entry: PowerShell migration, dotnet bootstrapping, pac auto-install/upgrade, platform bootstrappers |

### Step 7 — Re-install skill locally

```bash
gh skill install JohannesBertens/power-platform-skills power-platform-connect
```

Refreshes `.pi/skills/` with the new files.

## Testing Strategy

### Platform Tests

| Platform | Test Command | Expected Result |
|---|---|---|
| Linux | `bash skills/power-platform-connect/scripts/ensure-pwsh.sh` | Installs pwsh + dotnet if needed, runs check-pac.ps1, pac installed/upgraded |
| macOS | `bash skills/power-platform-connect/scripts/ensure-pwsh.sh` | Same as Linux |
| Windows | `skills\power-platform-connect\scripts\ensure-pwsh.cmd` | Installs pwsh + dotnet if needed, runs check-pac.ps1, pac installed/upgraded |
| Any (pwsh exists) | `pwsh skills/power-platform-connect/scripts/check-pac.ps1` | Directly checks/installs/upgrades pac |

### Edge Cases

- Fresh machine with nothing installed → full bootstrap chain (ensure-pwsh → install pwsh → install dotnet → check-pac → install pac)
- Machine with pwsh but no dotnet → dotnet installed, then pac
- Machine with everything → pac checked/upgraded silently
- Machine with outdated pac → auto-upgraded without prompt
- Machine with no internet → graceful failure with clear error message
- Windows without winget (e.g., Windows Server 2022) → MSI fallback

## PowerShell Installation Methods Reference

### Windows
- **Preferred**: `winget install --id Microsoft.PowerShell --source winget`
- **Fallback**: Download MSI from `https://github.com/PowerShell/PowerShell/releases/latest` and run `msiexec /quiet ADD_PATH=1`

### macOS
- **Preferred**: `brew install powershell/tap/powershell`
- **Fallback**: Download `.pkg` from GitHub releases, run `sudo installer -pkg ... -target /`

### Linux — Debian/Ubuntu
- Add Microsoft package repository (GPG keys + sources list)
- `sudo apt-get install -y powershell`

### Linux — RHEL/Fedora
- Add Microsoft repository
- `sudo dnf install -y powershell`

### Linux — Alpine
- `sudo apk add powershell` (community repo)

### Linux — Other (universal)
- Download `tar.gz` binary archive from GitHub releases
- Extract to `/usr/local/microsoft/powershell/7`
- Symlink `/usr/local/bin/pwsh`

### .NET SDK 8.0 Installation
- **Windows**: `winget install Microsoft.DotNet.SDK.8`
- **macOS**: `brew install dotnet@8`
- **Linux**: Use `dotnet-install.sh` script or distro-specific package repos
- **Universal script**: `https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh`

## Version Bump

**v1.0.4 → v1.1.0** (minor version bump)

New functionality: auto-install, dotnet bootstrapping, multi-platform bootstrappers, PowerShell migration. The skill's purpose (verify pac) remains backward-compatible.
